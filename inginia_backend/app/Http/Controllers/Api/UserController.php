<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    /**
     * Afficher tous les utilisateurs
     */
    public function index()
    {
        return response()->json(User::all(), 200);
    }

    /**
     * Créer un utilisateur
     */
    public function store(Request $request)
    {
        // Validation commune
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
            'phone' => 'required|min:8',
            'role' => 'required|in:client,professionnel,service',
            'profession' => 'nullable|string|max:100',
            'service_name' => 'nullable|string|max:150',
        ]);

        // Validation spécifique selon rôle
        if ($validated['role'] === 'professionnel' && empty($validated['profession'])) {
            return response()->json(['message' => 'Le champ profession est requis pour un professionnel'], 422);
        }

        if ($validated['role'] === 'service' && empty($validated['service_name'])) {
            return response()->json(['message' => 'Le champ service_name est requis pour un service'], 422);
        }

        $validated['password'] = Hash::make($validated['password']);

        $user = User::create($validated);

        return response()->json($user, 201);
    }

    /**
     * Afficher un utilisateur par ID
     */
    public function show($id)
    {
        $user = User::with(['professions', 'competances', 'reviewsReceived', 'completedServices'])
            ->find($id);

        if (! $user) {
            return response()->json(['error' => 'Utilisateur non trouvé'], 404);
        }

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'photo' => $user->photo,
            'location' => $user->location,
            'slogan' => $user->slogan,
            'role' => $user->role,
            'professions' => $user->professions->map(fn ($p) => $p->name), // tableau de noms
            'services' => $user->competances, // ou map si tu veux juste le nom
            'min_price' => $user->min_price ?? null,
            'rating' => $user->reviewsReceived->avg('note') ?? 0,
            'completedServices' => $user->completedServices,
            'reviewsReceived' => $user->reviewsReceived,
        ]);
    }

    /**
     * Mettre à jour un utilisateur
     */
    public function update(Request $request)
    {
        $user = $request->user();

        // Si c'est un changement de mot de passe
        if ($request->has('current_password')) {
            return $this->updatePassword($request, $user);
        }

        $data = $request->validate([
            'name' => 'nullable|string|max:255',
            'email' => 'nullable|email|unique:users,email,'.$user->id,
            'phone' => 'nullable|string|max:20',
            'adresse' => 'nullable|string',
            'location' => 'nullable|string',
            'profession_ids' => 'nullable|array',
            'profession_ids.*' => 'exists:professions,id',
            'min_price' => 'nullable|numeric',
            'slogan' => 'nullable|string|max:255',
            'profile_photo' => 'nullable|image|max:2048',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        // Upload photo si présente
        if ($request->hasFile('profile_photo')) {
            $file = $request->file('profile_photo');
            $photoName = time().'_'.$file->getClientOriginalName();
            $file->storeAs('public/profile_photos', $photoName);
            $data['photo'] = $photoName;
        }

        // Mise à jour des données de base
        $user->update(array_filter($data, fn ($value) => ! is_null($value)));

        // Mise à jour des professions si présentes
        if (isset($data['profession_ids'])) {
            $user->professions()->sync($data['profession_ids']);
        }

        return response()->json([
            'message' => 'Profil mis à jour avec succès',
            'user' => $user->load(['professions', 'competances']),
        ]);
    }

    /**
     * Mettre à jour le mot de passe
     */
    private function updatePassword(Request $request, $user)
    {
        $data = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        // Vérifier le mot de passe actuel
        if (!Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Le mot de passe actuel est incorrect'
            ], 422);
        }

        // Mettre à jour le mot de passe
        $user->update([
            'password' => Hash::make($data['password'])
        ]);

        return response()->json([
            'message' => 'Mot de passe modifié avec succès'
        ]);
    }
    /**
     * Supprimer un utilisateur
     */
    public function destroy($id)
    {
        $user = User::find($id);
        if (! $user) {
            return response()->json(['message' => 'Utilisateur non trouvé'], 404);
        }

        $user->delete();

        return response()->json(['message' => 'Utilisateur supprimé'], 200);
    }

    // Récupérer uniquement les prestataires et services pour l'interface client
    public function getProvidersAndServices(Request $request)
    {
        $user = auth()->user();
        $query = User::whereIn('role', ['prestataire', 'service'])
            ->where('is_available', true)
            ->where(function($q) {
                $q->where('role', '!=', 'prestataire')
                  ->orWhere('balance', '>', 0);
            });

        // 🔍 Recherche par nom ou profession
        if ($request->filled('q')) {
            $search = $request->q;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%$search%")
                  ->orWhere('slogan', 'like', "%$search%")
                  ->orWhereHas('professions', function ($qp) use ($search) {
                      $qp->where('name', 'like', "%$search%");
                  });
            });
        }

        // 🏷️ Filtre par profession
        if ($request->filled('profession_id')) {
            $query->whereHas('professions', function ($q) use ($request) {
                $q->where('professions.id', $request->profession_id);
            });
        }

        // 💰 Filtre par prix
        if ($request->filled('min_price')) {
            $query->where('min_price', '>=', $request->min_price);
        }
        if ($request->filled('max_price')) {
            $query->where('min_price', '<=', $request->max_price);
        }

        // ⭐ Filtre par note
        if ($request->filled('min_rating')) {
            $query->whereHas('reviewsReceived', function ($q) use ($request) {
                $q->havingRaw('AVG(note) >= ?', [$request->min_rating]);
            }, '>=', 1);
        }

        // 🟢 Filtre disponibilité
        if ($request->boolean('available')) {
            $query->where('is_available', true);
        }

        // 🗺️ Filtre par distance (Géolocalisation)
        if ($request->filled(['latitude', 'longitude'])) {
            $lat = $request->latitude;
            $lng = $request->longitude;
            $query->avecDistance($lat, $lng);
            
            if ($request->filled('radius')) {
                $query->having('distance', '<=', $request->radius);
            }
        }

        // ↕️ Tri
        $sort = $request->input('sort', 'default');
        switch ($sort) {
            case 'price_asc':
                $query->orderBy('min_price', 'asc');
                break;
            case 'price_desc':
                $query->orderBy('min_price', 'desc');
                break;
            case 'rating_desc':
                $query->withAvg('reviewsReceived', 'note')
                      ->orderByDesc('reviews_received_avg_note');
                break;
            case 'distance_asc':
                // Handled by avecDistance scope if lat/lng present
                break;
            default:
                $query->latest();
                break;
        }

        $perPage = $request->input('per_page', 15);
        $providers = $query->with(['professions', 'competances'])
                           ->withAvg('reviewsReceived', 'note')
                           ->paginate($perPage);

        // Ajouter info "favorited" pour l'utilisateur actuel
        $providers->getCollection()->transform(function ($provider) use ($user) {
            $provider->favorited = $user ? $user->favorites()->where('provider_id', $provider->id)->exists() : false;
            $provider->avg_rating = (float)($provider->reviews_received_avg_note ?? 0);
            return $provider;
        });

        return response()->json($providers);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
        ]);

        $user = auth('api')->user();

        if (! $user) {
            return response()->json(['error' => 'Utilisateur non authentifié'], 401);
        }

        $user->fcm_token = $request->token;
        $user->save();

        return response()->json(['success' => true, 'message' => 'FCM token mis à jour']);
    }
}
