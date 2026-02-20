<?php

namespace App\Http\Controllers;

use App\Events\UrgentRequestCreated;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class SOSController extends Controller
{
    /**
     * Déclencher une alerte SOS
     */
    public function store(Request $request, \App\Services\FcmService $fcmService)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'problem_type' => 'required|string', // ex: plomberie, electricité
            'description' => 'nullable|string',
        ]);

        $user = Auth::user();
        $data = [
            'user_id' => $user->id,
            'user_name' => $user->name,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'problem_type' => $request->problem_type,
            'description' => $request->description,
            'timestamp' => now()->toIso8601String(),
        ];

        try {
            broadcast(new UrgentRequestCreated($data))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Erreur Broadcast SOS: " . $e->getMessage());
        }

        // 🔔 Envoyer une notification Push aux prestataires à proximité (10km) et DISPONIBLES
        $providers = \App\Models\User::where('role', 'prestataire')
            ->where('is_available', true)
            ->avecDistance($request->latitude, $request->longitude)
            ->whereRaw("(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) <= 10", [$request->latitude, $request->longitude, $request->latitude])
            ->get();

        foreach ($providers as $provider) {
            $tokens = $provider->deviceTokens()->where('revoked', false)->pluck('token');
            if ($tokens->isNotEmpty()) {
                try {
                    $fcmService->sendToMultipleTokens(
                        $tokens->toArray(),
                        "🚨 URGENCE SOS : " . $request->problem_type,
                        "Un client a besoin d'aide immédiatement près de chez vous.",
                        array_merge($data, ['type' => 'urgent_request'])
                    );
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error("Erreur FCM SOS: " . $e->getMessage());
                }
            }
        }

        return response()->json([
            'message' => 'Alerte SOS enregistrée (diffusion en cours...)',
            'data' => $data
        ]);
    }

    public function accept(Request $request)
    {
        $request->validate([
            'client_id' => 'required|exists:users,id',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'problem_type' => 'required|string'
        ]);

        $provider = Auth::user();

        // 🔒 SECURITY: Le prestataire ne peut pas accepter de mission SOS si son solde est <= 0
        if ($provider->balance <= 0) {
            return response()->json([
                'error' => 'Solde insuffisant',
                'message' => 'Votre portefeuille est vide. Veuillez recharger votre compte pour accepter cette mission.'
            ], 403);
        }

        // Créer une réservation immédiate
        $reservation = \App\Models\Reservation::create([
            'client_id' => $request->client_id,
            'provider_id' => $provider->id,
            'other_service' => "URGENCE SOS: " . $request->problem_type,
            'requested_date' => now(),
            'status' => 'accepted', // Directement accepté
            'client_lat' => $request->latitude,
            'client_lng' => $request->longitude,
            'commentaire' => "Intervention d'urgence générée via SOS."
        ]);

        return response()->json([
            'message' => 'Mission acceptée',
            'reservation_id' => $reservation->id
        ]);
    }
}
