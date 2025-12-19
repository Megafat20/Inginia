<?php

namespace App\Http\Controllers;

use App\Models\Availability;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AvailabilityController extends Controller
{
    /**
     * Voir mes disponibilités (Prestataire) ou celles d'un autre (Client)
     */
    public function index(Request $request)
    {
        $userId = $request->query('provider_id') ?? Auth::id();
        
        $availabilities = Availability::where('user_id', $userId)
            ->where('is_active', true)
            ->get();

        return response()->json($availabilities);
    }

    /**
     * Mettre à jour mon planning (Prestataire uniquement)
     */
    public function update(Request $request)
    {
        $request->validate([
            'schedule' => 'required|array',
            'schedule.*.day' => 'required|string', // monday, tuesday...
            'schedule.*.start_time' => 'required|date_format:H:i',
            'schedule.*.end_time' => 'required|date_format:H:i|after:schedule.*.start_time',
        ]);

        $user = Auth::user();

        // On supprime l'ancien planning pour le remplacer par le nouveau (méthode simple)
        // Ou on fait un update intelligent par jour.
        // Ici : on remplace tout pour simplifier la gestion côté frontend React
        
        $user->availabilities()->delete();

        foreach ($request->schedule as $slot) {
            $user->availabilities()->create([
                'day' => $slot['day'],
                'start_time' => $slot['start_time'],
                'end_time' => $slot['end_time'],
                'is_active' => true,
            ]);
        }

        return response()->json(['message' => 'Planning mis à jour avec succès', 'schedule' => $user->availabilities]);
    }
}
