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

        $data = $request->validate([
            'nom' => 'nullable|string|max:255',
            'prenom' => 'nullable|string|max:255',
            'service' => 'nullable|string|max:255',
            'email' => 'required|email|unique:users,email,'.$user->id,
            'telephone' => 'nullable|string|max:20',
            'adresse' => 'nullable|string',
            'location' => 'nullable|string',
            'profession_ids' => 'nullable|array',
            'profession_ids.*' => 'exists:professions,id',
            'competances' => 'nullable|array',
            'competances.*' => 'exists:competances,id',
            'min_price' => 'nullable|numeric',
            'slogan' => 'nullable|string|max:255',
            'is_agency' => 'boolean',
            'profile_photo' => 'nullable|image|max:2048',
        ]);

        // Maj infos simples
        $user->update($data);

        // Synchro relations
        if ($request->has('profession_ids')) {
            $user->professions()->sync($request->profession_ids);
        }
        if ($request->has('competances')) {
            $user->competances()->sync($request->competances);
        }

        // Photo
        if ($request->hasFile('profile_photo')) {
            $path = $request->file('profile_photo')->store('profile_photos', 'public');
            $user->photo = basename($path);
            $user->save();
        }

        return response()->json($user->load(['professions', 'competances']));
    }


    public function updatePassword(Request $request)
{
    $user = $request->user();

    $data = $request->validate([
        'current_password' => 'required',
        'password' => 'required|confirmed|min:8',
    ]);

    if (!\Hash::check($data['current_password'], $user->password)) {
        return response()->json(['error' => 'Mot de passe actuel incorrect'], 422);
    }

    $user->password = bcrypt($data['password']);
    $user->save();

    return response()->json(['message' => 'Mot de passe mis à jour avec succès']);
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
    public function getProvidersAndServices()
    {
        $user = auth()->user();
        $users = User::whereIn('role', ['prestataire', 'service'])
            ->with('professions') // si tu veux inclure les professions
            ->get()
            ->map(function ($provider) use ($user) {
                $provider->favorited = $user->favorites()->where('provider_id', $provider->id)->exists();

                return $provider;
            });

        return response()->json($users);
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
