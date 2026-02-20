<?php

namespace App\Http\Controllers;

use App\Models\Reservation;
use App\Models\User;
use Illuminate\Http\Request;
use App\Events\ReservationCreated;
use App\Events\ReservationStatusUpdated;
use App\Models\Message;
use Illuminate\Support\Facades\Auth;
use App\Services\FcmService;
use App\Events\MessageSent;
use App\Models\Portfolio;

class ReservationController extends Controller
{
    protected $fcm;

    public function __construct(FcmService $fcm)
    {
        $this->fcm = $fcm;
    }

    public function notifyProvider($providerId, $reservationId)
    {
        $provider = User::findOrFail($providerId);
        $reservation = Reservation::findOrFail($reservationId);

        if (!$provider->fcm_token) {
            return response()->json(['message' => 'Le prestataire n’a pas de token FCM']);
        }
        $clientName = $reservation->client ? $reservation->client->name : "un client";
        $title = "Nouvelle réservation !";
        $body = "Vous avez une nouvelle réservation de " . $clientName;

        $this->fcm->sendToToken($provider->fcm_token, $title, $body);

        return response()->json(['message' => 'Notification envoyée !']);
    }

    public function sendNotification(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'title' => 'required|string',
            'body' => 'required|string',
        ]);

        $this->fcm->sendToToken(
            $request->token,
            $request->title,
            $request->body,
            $request->data ?? []
        );

        return response()->json(['message' => 'Notification envoyée !']);
    }


    public function index(Request $request)
    {
        $providerId = auth()->id();
        $reservations = Reservation::with('client', 'competance')
            ->where('provider_id', $providerId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['reservations' => $reservations]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,accepted,declined,completed,cancelled,in_progress',
            'reason' => 'nullable|string|max:500', // Added for cancellation reason
        ]);

        $reservation = Reservation::with(['client', 'competance'])->findOrFail($id);
        $user = auth()->user();

        // Sécurité : Seul le client ou le prestataire lié peut modifier
        if ($reservation->provider_id !== $user->id && $reservation->client_id !== $user->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $oldStatus = $reservation->status;
        $newStatus = $request->status;

        // Logique d'annulation
        if ($newStatus === 'cancelled') {
            $reservation->status = 'cancelled';
            $reservation->cancellation_reason = $request->reason ?? 'Non spécifié';
            $reservation->cancelled_at = now();
            $reservation->cancelled_by = $user->id === $reservation->client_id ? 'client' : 'provider';
            $reservation->save();

            broadcast(new ReservationStatusUpdated($reservation))->toOthers();

            return response()->json([
                'message' => 'Réservation annulée',
                'reservation' => $reservation
            ]);
        }

        // Autres status : seul le prestataire peut les changer (accepté, en cours, terminé)
        if ($reservation->provider_id !== $user->id) {
            return response()->json(['message' => 'Seul le prestataire peut valider cette étape'], 403);
        }

        $reservation->status = $newStatus;
        $reservation->save();

        // 💰 Déduction automatique de commission si mission terminée
        if ($newStatus === 'completed') {
            $this->deductCommission($reservation);
        }

        broadcast(new ReservationStatusUpdated($reservation))->toOthers();

        if ($newStatus === 'accepted') {
            $reservation->load(['client', 'competance']);
            return response()->json([
                'message' => 'Réservation acceptée',
                'reservation' => $reservation,
                'client_location' => [
                    'lat' => $reservation->client_lat,
                    'lng' => $reservation->client_lng
                ]
            ]);
        }

        return response()->json([
            'message' => 'Statut mis à jour avec succès',
            'reservation' => $reservation,
        ]);
    }

    /**
     * Déduit la commission Inginia du solde du prestataire
     */
    private function deductCommission($reservation)
    {
        $provider = $reservation->provider;
        
        // 📊 Calcul de la commission (5% du prix du service ou 200 FCFA minimum)
        $servicePrice = $reservation->competance->price ?? 4000; // Prix par défaut si non défini
        $commissionRate = 0.05; // 5%
        $commission = max(200, $servicePrice * $commissionRate); // Minimum 200 FCFA

        // 💸 Déduction systématique (permet le solde négatif)
        $provider->balance -= $commission;

        // 🔒 Si le solde est nul ou négatif, on désactive le prestataire
        if ($provider->balance <= 0) {
            $provider->is_available = false;
        }

        $provider->save();

        // 📝 Enregistrement de la transaction (toujours complétée car déduite du solde)
        \App\Models\Transaction::create([
            'user_id' => $provider->id,
            'type' => 'debit',
            'amount' => $commission,
            'status' => 'completed',
            'payment_method' => 'system',
            'reference' => 'COMM_' . $reservation->id,
            'description' => "Commission Inginia - Mission #{$reservation->id}" . ($provider->balance < 0 ? " (Compte en découvert)" : ""),
        ]);
    }




    public function store(Request $request, $provider_id)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['error' => 'Non connecté'], 401);
        }

        // Validation
        $validated = $request->validate([
            'service_id' => 'nullable|integer|exists:services,id',
            'other_service' => 'nullable|string|max:255',
            'requested_date' => 'required|date',
            'comment' => 'nullable|string|max:1000',
        ]);

        $provider = User::find($provider_id);
        if (!$provider || $provider->role !== 'prestataire') {
            return response()->json(['error' => 'Prestataire introuvable'], 404);
        }

        // Créer la réservation
        $reservation = new Reservation();
        $reservation->client_id = $user->id;
        $reservation->provider_id = $provider->id;
        $reservation->service_id = $validated['service_id'] ?? null;
        $reservation->other_service = $validated['other_service'] ?? null;
        $reservation->requested_date = $validated['requested_date'];
        $reservation->commentaire = $validated['comment'] ?? null;
        $reservation->status = 'pending';
        $reservation->client_lat = $request->input('latitude');
        $reservation->client_lng = $request->input('longitude');
        $reservation->save();

        broadcast(new ReservationCreated($reservation))->toOthers();

        return response()->json([
            'message' => 'Réservation envoyée',
            'reservation' => $reservation,
        ]);
    }

    public function getForProvider($providerId)
    {
        try {
            $user = Auth::user(); // client connecté
            $provider = User::findOrFail($providerId);

            $reservation = Reservation::with(['client', 'competance'])
                ->where('provider_id', $provider->id)
                ->where('client_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->first(); // une seule réservation, la plus récente

            return response()->json(['reservation' => $reservation]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Erreur lors de la récupération de la réservation',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getMyReservations()
    {
        $clientId = Auth::id();
        $reservations = Reservation::with(['provider', 'competance'])
            ->where('client_id', $clientId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['reservations' => $reservations]);
    }

    public function getClientReservationsForProvider($providerId)
    {
        $clientId = Auth::id(); // Id du client connecté

        $reservations = Reservation::with('competance')
            ->where('client_id', $clientId)
            ->where('provider_id', $providerId)
            ->orderBy('requested_date', 'desc')
            ->get();

        return response()->json($reservations);
    }

    public function show($id)
    {
        $reservation = Reservation::with(['client', 'provider', 'competance'])->findOrFail($id);
        
        // Sécurité : Seul le client ou le prestataire peut voir
        if ($reservation->client_id !== auth()->id() && $reservation->provider_id !== auth()->id()) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        return response()->json($reservation);
    }


    public function sendMessage(Request $request, $reservationId)
    {
        $request->validate([
            'content' => 'nullable|string',
            'image' => 'nullable|image|max:5000', // max 5MB
            'audio' => 'nullable|file|mimes:mp3,wav,m4a,aac,oga,mp4|max:10000', // max 10MB
        ]);

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('chat', 'public');
            $imageUrl = $path;
        }

        $audioUrl = null;
        if ($request->hasFile('audio')) {
            $path = $request->file('audio')->store('chat/audio', 'public');
            $audioUrl = $path;
        }

        $message = Message::create([
            'reservation_id' => $reservationId,
            'sender_id' => auth()->id(),
            'message' => $request->input('content'),
            'image_url' => $imageUrl,
            'audio_url' => $audioUrl,
        ]);

        broadcast(new MessageSent($message))->toOthers();

        return response()->json(['message' => $message], 201);
    }



    public function getMessages($reservationId)
    {
        $messages = Message::with('user')->where('reservation_id', $reservationId)
            ->orderBy('created_at')
            ->get();
        return response()->json(['messages' => $messages]);
    }

    public function updateLocation(Request $request, $id)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $reservation = Reservation::findOrFail($id);
        $user = auth()->user();

        if ($reservation->provider_id === $user->id) {
            // Prestataire qui bouge
            $reservation->update([
                'provider_lat' => $request->latitude,
                'provider_lng' => $request->longitude,
            ]);

            broadcast(new \App\Events\ProviderLocationUpdated(
                $user->id,
                $reservation->id,
                $request->latitude,
                $request->longitude
            ))->toOthers();

            return response()->json(['status' => 'ok', 'role' => 'provider']);
        } elseif ($reservation->client_id === $user->id) {
            // Client qui bouge
            $reservation->update([
                'client_lat' => $request->latitude,
                'client_lng' => $request->longitude,
            ]);

            broadcast(new \App\Events\ClientLocationUpdated(
                $user->id,
                $reservation->id,
                $request->latitude,
                $request->longitude
            ))->toOthers();

            return response()->json(['status' => 'ok', 'role' => 'client']);
        }

        return response()->json(['error' => 'Non autorisé'], 403);
    }



    public function getOngoingReservations()
    {
        // Seul l'admin peut voir toutes les réservations en cours
        if (auth()->user()->role !== 'admin') {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $reservations = Reservation::with(['client', 'provider', 'competance'])
            ->where('status', 'accepted') // On suit ceux qui sont acceptés (en route)
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json(['reservations' => $reservations]);
    }

    public function uploadPhotos(Request $request, $id)
    {
        $request->validate([
            'photos' => 'required|array',
            'photos.*' => 'image|max:5120',
            'type' => 'required|in:before,after',
        ]);

        $reservation = Reservation::findOrFail($id);
        $user = auth()->user();

        if ($reservation->provider_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $uploadedPhotos = [];
        foreach ($request->file('photos') as $photo) {
            $path = $photo->store('portfolios', 'public');
            
            $portfolio = Portfolio::create([
                'provider_id' => $user->id,
                'reservation_id' => $reservation->id,
                'image_path' => basename($path),
                'type' => $request->type,
                'title' => ($request->type === 'before' ? 'Avant : ' : 'Après : ') . ($reservation->competance->name ?? 'Service'),
                'description' => "Photo " . $request->type . " réalisée pour " . ($reservation->client->name ?? 'un client'),
            ]);
            $uploadedPhotos[] = $portfolio;
        }

        return response()->json([
            'message' => 'Photos ajoutées au portfolio',
            'photos' => $uploadedPhotos
        ]);
    }
}
