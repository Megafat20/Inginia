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
        ]);

        // Vérifier que le prestataire existe bien
        $prestataire = User::where('id', $prestataire_id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        // Création de l'avis
        $review = Avis::create([
            'client_id' => auth()->id(),
            'prestataire_id' => $prestataire->id,
            'note' => $request->rating,
            'commentaire' => $request->comment,
        ]);

        // Recalculer la note moyenne du prestataire
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
                    'note' => $review->note,
                    'commentaire' => $review->commentaire,
                    'client_name' => $review->client->name,
                    'client_photo' => $review->client->photo,
                ];
            });
        return response()->json([
            'prestataire' => $prestataire->name,
            'rating' => $prestataire->rating,
            'reviews' => $reviews
        ]);
    }

}
