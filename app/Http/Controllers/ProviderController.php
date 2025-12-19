<?php

namespace App\Http\Controllers;

use App\Models\Service;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;


class ProviderController extends Controller
{

    public function index()
    {
        $providers = User::with('professions', 'competances')
            ->whereIn('role', ['prestataire', 'service'])
            ->get()
            ->map(fn($u) => [
                'id' => $u->id,
                'name' => $u->name,
                'photo' => $u->photo,
                'location' => $u->location,
                'slogan' => $u->slogan,
                'verified' => $u->verified,
                'role' => $u->role,
                'profession' => $u->professions, // pour les professionnels
                'service_name' => $u->service_name, // pour les agences
                'min_price' => $u->min_price,
            ]);

        return response()->json($providers);
    }

    public function myProfessions()
    {
        $user = Auth::user();

        // Vérifier que c'est un prestataire ou service
        if (!in_array($user->role, ['prestataire', 'service'])) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $professions = $user->professions()->get([
            'professions.id',
            'professions.name'
        ]);

        return response()->json([
            'professions' => $professions
        ]);

    }
    public function addService(Request $request)
    {
        $user = Auth::user();

        // Vérifier que l'utilisateur est bien prestataire ou agence
        if (!in_array($user->role, ['prestataire', 'service'])) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Validation des champs
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'nullable|numeric',
            'profession_id' => 'required|integer|exists:professions,id',
        ]);

        // Création du service
        $service = Service::create([
            'provider_id' => $user->id,
            'title' => $validated['title'],
            'description' => $request->input('description', null),
            'price' => $validated['price'] ?? null,
            'profession_id' => $validated['profession_id'],
        ]);

        return response()->json([
            'message' => 'Service ajouté avec succès',
            'service' => $service
        ], 201);
    }

    // public function getServicesByProviderId($id)
// {
//     $provider = User::with('competances.profession')->find($id);

    //     if (!$provider) {
//         return response()->json(['error' => 'Prestataire introuvable'], 404);
//     }

    //     return response()->json([
//         'provider' => [
//             'id' => $provider->id,
//             'name' => $provider->name,
//             'role' => $provider->role,
//             'photo' => $provider->photo,
//         ],
//         'competances' => $provider->competances
//     ]);
// }
//     // Statistiques du prestataire
//     public function getProviderStat()
//     {
//         $user = Auth::user();

    //         if (!in_array($user->role, ['prestataire', 'service'])) {
//             return response()->json(['error' => 'Non autorisé'], 403);
//         }

    //         $servicesCount = $user->competances()->count();
//         $reservationsCount = $user->receivedReservations()->count();
//         $completedReservations = $user->receivedReservations()
//             ->where('status', 'completed')
//             ->count();

    //         return response()->json([
//             'profile' => [
//                 'id' => $user->id,
//                 'name' => $user->name,
//                 'email' => $user->email,
//                 'professions' => $user->professions()->select('professions.id', 'professions.name')->get(),
//                 'location' => $user->location ?? '',
//                 'note' => $user->reviewsReceived()->avg('note') ?? 0,
//                 'photo' => $user->photo,
//             ],
//             'stats' => [
//                 'totalServices' => $servicesCount,
//                 'totalReservations' => $reservationsCount,
//                 'completedReservations' => $completedReservations,
//             ]
//         ]);
//     }


public function getFullDashboard($id)
{
    $provider = User::with(['competances', 'professions'])->find($id);
    if (!$provider) {
        return response()->json(['error' => 'Prestataire introuvable'], 404);
    }

    // Avis récents avec info client
    $reviews = $provider->reviewsReceived()
        ->with('client:id,name,photo')
        ->latest()
        ->take(10)
        ->get();

    // Réservations reçues avec info client et service
    $reservations = $provider->receivedReservations()
        ->with(['client:id,name,photo', 'competance:id,title'])
        ->latest()
        ->get();

    // Transforme professions pour frontend
    $professions = $provider->professions->map(fn($p) => ['id'=>$p->id, 'name'=>$p->name]);

    return response()->json([
        'provider' => [
            'id' => $provider->id,
            'name' => $provider->name,
            'role' => $provider->role,
            'photo' => $provider->photo,
            'phone' => $provider->phone,
            'email' => $provider->email,
            'location' => $provider->location,
            'slogan' => $provider->slogan ?? null,
            'min_price' => $provider->competances->min('price') ?? null,
            'rating' => round($provider->reviewsReceived()->avg('note') ?? 0, 1),
            'professions' => $professions,
        ],
        'competances' => $provider->competances,
        'stats' => [
            'total_services' => $provider->competances()->count(),
            'total_reviews' => $provider->reviewsReceived()->count(),
        ],
        'reviews' => $reviews,
        'reservations' => $reservations,
    ]);
}



    // Récupérer tous les services du prestataire

    public function popularProfessions()
    {
        $professions = User::where('role', 'prestataire')
            ->select('profession', DB::raw('COUNT(*) as total'))
            ->groupBy('profession')
            ->orderByDesc('total')
            ->take(5)
            ->get();

        return response()->json($professions);
    }

    // Récupérer tous les prestataires d’une profession donnée
    public function prestatairesByProfession($profession)
    {
        $prestataires = User::where('role', 'prestataire')
            ->where('profession', $profession)
            ->select('id', 'name', 'email', 'profession', 'created_at')
            ->get();

        return response()->json($prestataires);
    }


    // app/Http/Controllers/ProviderController.php


}
