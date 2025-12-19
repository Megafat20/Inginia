<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Google\Client as GoogleClient;
use Illuminate\Support\Str;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\LoginRequest;

class AuthController extends Controller
{
    public function register(RegisterRequest $request)
    {
        // Validation automatique via RegisterRequest

        // Upload photo si présente
        $photoName = null;
        if ($request->hasFile('profile_photo')) {
            $file = $request->file('profile_photo');
            $photoName = time().'_'.$file->getClientOriginalName();
            $file->storeAs('public/profile_photos', $photoName);
        }

        // Création de l'utilisateur
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'role' => $request->role ?? 'user',
            'service' => $request->service,
            'location' => $request->location,
            'adresse' => $request->adresse,
            'photo' => $photoName,
            'min_price' => $request->min_price,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'slogan' => $request->slogan,
        ]);

        // Attacher les professions si elles existent
        if ($request->has('profession_ids')) {
            $user->professions()->sync($request->profession_ids);
        }

        // Création du token
        $token = $user->createToken('LaravelPassportToken')->accessToken;

        // Réponse JSON
        return response()->json([
            'message' => 'Utilisateur enregistré avec succès',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'service_name' => $user->service_name,
                'location' => $user->location,
                'min_price' => $user->min_price,
                'slogan' => $user->slogan,
                'profile_photo' => $user->photo
                    ? asset('storage/profile_photos/'.$user->photo)
                    : null,
                'professions' => $user->professions->map(fn ($p) => [
                    'id' => $p->id,
                    'name' => $p->name,
                ]),
            ],
            'token' => $token,
        ], 201);
    }

    public function login(LoginRequest $request)
    {
        $credentials = $request->only('email', 'password');
        
        if (! Auth::attempt($credentials)) {
            return response()->json(['error' => 'Email ou mot de passe invalide'], 401);
        }
        $user = Auth::user();
        $token = $user->createToken('LaravelPassportToken')->accessToken;

        return response()->json(['message' => 'Connexion réussie', 'user' => $user, 'token' => $token]);
    }

    public function googleLogin(Request $request)
    {
        $request->validate([
            'credential' => 'required|string',
        ]);

        $client = new GoogleClient(['client_id' => config('services.google.client_id')]);
        $payload = $client->verifyIdToken($request->credential);

        if (! $payload) {
            return response()->json(['error' => 'Token Google invalide'], 401);
        }

        $email = $payload['email'];
        $name = $payload['name'] ?? explode('@', $email)[0];
        $picture = $payload['picture'] ?? null;

        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'google_id' => $payload['sub'],
                'password' => bcrypt(Str::random(16)),
                'photo' => $picture,
                'role' => 'client', // Par défaut client (modifiable selon ton app)
            ]   
        );

        $token = $user->createToken('LaravelPassportToken')->accessToken;

        return response()->json([
            'message' => 'Connexion Google réussie',
            'user' => $user,
            'token' => $token,
        ]);
    }

    // 🔹 Déconnexion
    public function logout(Request $request)
    {
        $request->user()->token()->revoke();

        return response()->json(['message' => 'Décon    nexion réussie']);
    }

    // 🔹 Utilisateur connecté
    // UserController.php
    public function me(Request $request)
    {
        $user = $request->user()->load(['professions', 'competances']);

        return response()->json($user);
    }
}
