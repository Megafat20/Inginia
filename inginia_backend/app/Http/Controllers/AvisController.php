<?php

namespace App\Http\Controllers;

use App\Models\Avis;
use App\Models\User;
use Illuminate\Http\Request;

use Illuminate\Http\JsonResponse;

class AvisController extends Controller
{

    public function store(Request $request, $prestataire_id)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'reservation_id' => 'required|exists:reservations,id'
        ]);

        $reservationId = $request->reservation_id;

        // Vérifier que la mission existe, appartient au client et est TERMINÉE
        $reservation = \App\Models\Reservation::where('id', $reservationId)
            ->where('client_id', auth()->id())
            ->where('provider_id', $prestataire_id)
            ->where('status', 'completed')
            ->first();

        if (!$reservation) {
            return response()->json([
                'error' => 'Vous ne pouvez laisser un avis que pour une mission terminée avec ce prestataire.'
            ], 403);
        }

        // Vérifier si un avis a déjà été laissé pour cette réservation
        $existing = Avis::where('reservation_id', $reservationId)->first();
        if ($existing) {
            return response()->json(['error' => 'Un avis a déjà été laissé pour cette mission.'], 403);
        }

        // Création de l'avis
        $review = Avis::create([
            'client_id' => auth()->id(),
            'prestataire_id' => $prestataire_id,
            'reservation_id' => $reservationId,
            'note' => $request->rating,
            'commentaire' => $request->comment,
        ]);

        // Recalculer la note moyenne du prestataire
        $prestataire = User::findOrFail($prestataire_id);
        $average = Avis::where('prestataire_id', $prestataire->id)->avg('note');
        $prestataire->rating = round($average, 2);
        $prestataire->save();

        return response()->json([
            'message' => 'Avis ajouté avec succès',
            'review' => $review,
            'new_rating' => $prestataire->rating
        ]);
    }


    public function show($prestataire_id)
    {
        $prestataire = User::where('id', $prestataire_id)
            ->where('role', 'prestataire','service')
            ->firstOrFail();

            $reviews = Avis::where('prestataire_id', $prestataire->id)
            ->with('client:id,name,photo')
            ->latest()
            ->get()
            ->map(function ($review) {
                return [
                    'id' => $review->id,
                    'rating' => $review->note,
                    'comment' => $review->commentaire,
                    'reviewer_name' => $review->client->name,
                    'reviewer_photo' => $review->client->photo,
                    'created_at' => $review->created_at,
                ];
            });
        return response()->json([
            'prestataire' => $prestataire->name,
            'rating' => $prestataire->rating,
            'reviews' => $reviews
        ]);
    }

}
