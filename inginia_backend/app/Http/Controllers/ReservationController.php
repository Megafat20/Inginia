<?php

namespace App\Http\Controllers;

use App\Models\Reservation;
use App\Models\User;
use Illuminate\Http\Request;
use App\Events\MessageSent;
use App\Models\Message;
use Illuminate\Support\Facades\Auth;
use App\Services\FcmService;
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

    public function updateStatus(Request $request, $id, FcmService $fcm)
    {
        $request->validate([
            'status' => 'required|in:pending,accepted,declined,completed',
        ]);

        $reservation = Reservation::with(['client', 'competance'])->findOrFail($id);

        if ($reservation->provider_id !== auth()->id()) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $reservation->status = $request->status;
        $reservation->save();

        if ($request->status === 'accepted') {
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

        // 🔔 Envoyer la notif
        $title = "Réservation mise à jour";
        $body = match ($request->status) {
            'accepted' => "Le prestataire a accepté votre réservation",
            'declined' => "Le prestataire a refusé votre réservation",
            'completed' => "Votre réservation est terminée",
            default => "Votre réservation est en attente",
        };

        if ($reservation->client && $reservation->client->fcm_token) {
            $this->fcm->sendToToken($reservation->client->fcm_token, $title, $body);
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


    public function sendMessage(Request $request, $reservationId, FcmService $fcmService)
    {
        $request->validate([
            'content' => 'required|string',
        ]);

        $message = Message::create([
            'reservation_id' => $reservationId,
            'sender_id' => auth()->id(),
            'message' => $request->input('content'),
        ]);

        broadcast(new MessageSent($message))->toOthers();

        $reservation = Reservation::with(['client', 'provider'])->findOrFail($reservationId);
        $recipient = $reservation->client_id === auth()->id()
            ? $reservation->provider
            : $reservation->client;

        // Notif In-App instantanée
        broadcast(new \App\Events\UserNotification(
            $recipient->id,
            "Nouveau message de " . auth()->user()->name,
            $message->message,
            ['type' => 'chat', 'reservation_id' => $reservationId]
        ));

        $recipientTokens = $recipient->deviceTokens()->where('revoked', false)->pluck('token');

        if ($recipientTokens->isNotEmpty()) {
            try {
                // Utilisation correcte avec array
                $fcmService->sendNotification(
                    $recipientTokens->toArray(),
                    "Nouveau message de " . auth()->user()->name,
                    $message->message
                );
            } catch (\Exception $e) {
                // Log silentieux pour ne pas bloquer l'envoi du message
                \Illuminate\Support\Facades\Log::error("Erreur FCM Chat: " . $e->getMessage());
            }
        }

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

        broadcast(new \App\Events\ProviderLocationUpdated(
            Auth::id(),
            $reservation->id,
            $request->latitude,
            $request->longitude
        ))->toOthers();

        return response()->json(['status' => 'ok']);
    }



}
