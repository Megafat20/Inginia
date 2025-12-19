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
    public function store(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'problem_type' => 'required|string', // ex: plomberie, electricité
            'description' => 'nullable|string',
        ]);

        $data = [
            'user_id' => Auth::id(),
            'user_name' => Auth::user()->name,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'problem_type' => $request->problem_type,
            'description' => $request->description,
            'timestamp' => now()->toIso8601String(),
        ];

        try {
            broadcast(new UrgentRequestCreated($data))->toOthers();
        } catch (\Exception $e) {
            // On loggue l'erreur mais on continue (Soft Fail)
            \Illuminate\Support\Facades\Log::error("Erreur Broadcast SOS: " . $e->getMessage());
        }

        // (Optionnel) Ici on pourrait aussi sauvegarder en BDD dans une table 'urgent_requests'

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
