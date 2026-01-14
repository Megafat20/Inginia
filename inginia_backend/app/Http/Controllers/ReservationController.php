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
        ]);

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('chat', 'public');
            $imageUrl = $path;
        }

        $message = Message::create([
            'reservation_id' => $reservationId,
            'sender_id' => auth()->id(),
            'message' => $request->input('content'),
            'image_url' => $imageUrl,
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

        if ($reservation->provider_id !== Auth::id()) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Sauvegarder la position dans la base de données
        $reservation->update([
            'provider_lat' => $request->latitude,
            'provider_lng' => $request->longitude,
        ]);

        // Diffuser la nouvelle position via WebSocket (Pusher/Reverb)
        broadcast(new \App\Events\ProviderLocationUpdated(
            Auth::id(),
            $reservation->id,
            $request->latitude,
            $request->longitude
        ))->toOthers();

        return response()->json(['status' => 'ok']);
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

}
