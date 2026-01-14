<?php

namespace App\Http\Controllers;

use App\Models\Avis;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AvisController extends Controller
{
    /**
     * Créer un avis enrichi avec critères détaillés et photos
     */
    public function store(Request $request, $prestataire_id)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'reservation_id' => 'required|exists:reservations,id',
            
            // Critères détaillés (optionnels)
            'ponctualite' => 'nullable|integer|min:1|max:5',
            'qualite' => 'nullable|integer|min:1|max:5',
            'prix' => 'nullable|integer|min:1|max:5',
            'communication' => 'nullable|integer|min:1|max:5',
            
            // Photos (max 5)
            'photos' => 'nullable|array|max:5',
            'photos.*' => 'image|max:5120', // 5MB max per image
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

        // Upload des photos
        $photoPaths = [];
        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $photo) {
                $path = $photo->store('avis_photos', 'public');
                $photoPaths[] = $path;
            }
        }

        // Création de l'avis
        $review = Avis::create([
            'client_id' => auth()->id(),
            'prestataire_id' => $prestataire_id,
            'reservation_id' => $reservationId,
            'note' => $request->rating,
            'commentaire' => $request->comment,
            'ponctualite' => $request->ponctualite,
            'qualite' => $request->qualite,
            'prix' => $request->prix,
            'communication' => $request->communication,
            'photos' => $photoPaths,
            'verified' => true, // Vérifié car lié à une réservation complétée
        ]);

        // Recalculer la note moyenne du prestataire
        $prestataire = User::findOrFail($prestataire_id);
        $average = Avis::where('prestataire_id', $prestataire->id)->avg('note');
        $prestataire->rating = round($average, 2);
        $prestataire->save();

        return response()->json([
            'message' => 'Avis ajouté avec succès',
            'review' => $review->load('client:id,name,photo'),
            'new_rating' => $prestataire->rating
        ], 201);
    }

    /**
     * Récupérer les avis d'un prestataire avec filtres
     */
    public function show(Request $request, $prestataire_id)
    {
        $prestataire = User::where('id', $prestataire_id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        $query = Avis::where('prestataire_id', $prestataire->id)
            ->with('client:id,name,photo');

        // Filtres
        if ($request->has('min_rating')) {
            $query->byRating($request->min_rating);
        }

        if ($request->has('with_photos') && $request->with_photos) {
            $query->withPhotos();
        }

        if ($request->has('verified') && $request->verified) {
            $query->verified();
        }

        // Tri
        $sortBy = $request->get('sort_by', 'recent');
        switch ($sortBy) {
            case 'helpful':
                $query->orderBy('helpful_count', 'desc');
                break;
            case 'rating_high':
                $query->orderBy('note', 'desc');
                break;
            case 'rating_low':
                $query->orderBy('note', 'asc');
                break;
            default:
                $query->latest();
        }

        $reviews = $query->get()->map(function ($review) {
            return [
                'id' => $review->id,
                'rating' => $review->note,
                'comment' => $review->commentaire,
                'criteria' => [
                    'ponctualite' => $review->ponctualite,
                    'qualite' => $review->qualite,
                    'prix' => $review->prix,
                    'communication' => $review->communication,
                ],
                'photos' => $review->photos ? array_map(function($path) {
                    return asset('storage/' . $path);
                }, $review->photos) : [],
                'reviewer_name' => $review->client->name,
                'reviewer_photo' => $review->client->photo,
                'verified' => $review->verified,
                'helpful_count' => $review->helpful_count,
                'reponse_prestataire' => $review->reponse_prestataire,
                'reponse_at' => $review->reponse_at,
                'created_at' => $review->created_at,
            ];
        });

        // Statistiques
        $stats = [
            'total' => $reviews->count(),
            'average' => $prestataire->rating,
            'distribution' => [
                5 => Avis::where('prestataire_id', $prestataire->id)->where('note', 5)->count(),
                4 => Avis::where('prestataire_id', $prestataire->id)->where('note', 4)->count(),
                3 => Avis::where('prestataire_id', $prestataire->id)->where('note', 3)->count(),
                2 => Avis::where('prestataire_id', $prestataire->id)->where('note', 2)->count(),
                1 => Avis::where('prestataire_id', $prestataire->id)->where('note', 1)->count(),
            ],
            'criteria_averages' => [
                'ponctualite' => round(Avis::where('prestataire_id', $prestataire->id)->whereNotNull('ponctualite')->avg('ponctualite'), 1),
                'qualite' => round(Avis::where('prestataire_id', $prestataire->id)->whereNotNull('qualite')->avg('qualite'), 1),
                'prix' => round(Avis::where('prestataire_id', $prestataire->id)->whereNotNull('prix')->avg('prix'), 1),
                'communication' => round(Avis::where('prestataire_id', $prestataire->id)->whereNotNull('communication')->avg('communication'), 1),
            ],
        ];

        return response()->json([
            'prestataire' => $prestataire->name,
            'rating' => $prestataire->rating,
            'stats' => $stats,
            'reviews' => $reviews
        ]);
    }

    /**
     * Répondre à un avis (prestataire uniquement)
     */
    public function respond(Request $request, $avis_id)
    {
        $request->validate([
            'reponse' => 'required|string|max:500',
        ]);

        $avis = Avis::findOrFail($avis_id);

        // Vérifier que c'est bien le prestataire concerné
        if ($avis->prestataire_id !== auth()->id()) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $avis->update([
            'reponse_prestataire' => $request->reponse,
            'reponse_at' => now(),
        ]);

        return response()->json([
            'message' => 'Réponse ajoutée avec succès',
            'avis' => $avis
        ]);
    }

    /**
     * Marquer un avis comme utile
     */
    public function markHelpful($avis_id)
    {
        $avis = Avis::findOrFail($avis_id);
        $avis->increment('helpful_count');

        return response()->json([
            'message' => 'Merci pour votre retour',
            'helpful_count' => $avis->helpful_count
        ]);
    }
}
