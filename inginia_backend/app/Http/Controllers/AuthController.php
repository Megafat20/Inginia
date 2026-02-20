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
use App\Models\OtpVerification;
use App\Models\UserRefreshToken;
use Carbon\Carbon;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    public function sendOtp(Request $request)
    {
        $request->validate([
            'identifier' => 'required|string',
            'type' => 'required|in:email,phone',
        ]);

        $identifier = trim($request->identifier);
        $type = $request->type;

        return $this->sendOtpInternal($identifier, $type);
    }

    private function sendOtpInternal($identifier, $type)
    {
        // Generate 6-digit code
        $code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Store OTP
        OtpVerification::updateOrCreate(
            ['identifier' => $identifier, 'type' => $type],
            [
                'code' => $code,
                'attempts' => 0,
                'expires_at' => Carbon::now()->addMinutes(10),
                'verified_at' => null,
            ]
        );

        // Send OTP
        if ($type === 'email') {
            try {
                Mail::raw("Votre code de vérification Inginia est : $code", function ($message) use ($identifier) {
                    $message->to($identifier)->subject('Code de vérification Inginia');
                });
            } catch (\Exception $e) {
                \Log::error("Failed to send email OTP: " . $e->getMessage());
                return response()->json(['error' => 'Erreur lors de l\'envoi de l\'email'], 500);
            }
        } else {
            // Envoi par SMS
            $this->sendSms($identifier, "Votre code de vérification Inginia est : $code");
        }

        return response()->json(['message' => 'Code envoyé avec succès']);
    }

    private function sendSms($phone, $message)
    {
        // TODO: Intégrer ici votre fournisseur SMS (Twilio, Vonage, Infobip, etc.)
        // Pour l'instant, on loggue juste le message dans les fichiers de log (storage/logs/laravel.log)
        \Log::info("SMS envoyé à $phone : $message");

        // Exemple d'implémentation future :
        /*
        Http::post('https://api.sms-provider.com/send', [
            'to' => $phone,
            'text' => $message,
            'api_key' => config('services.sms.key')
        ]);
        */
    }

    public function verifyOtp(Request $request)
    {
        $request->validate([
            'identifier' => 'required|string',
            'code' => 'required|string',
            'type' => 'required|in:email,phone',
        ]);

        $identifier = trim($request->identifier);
        $reqCode = trim($request->code);
        $type = $request->type;

        $otp = OtpVerification::where('identifier', $identifier)
            ->where('type', $type)
            ->first();

        if (!$otp) {
            return response()->json(['error' => 'Aucun code trouvé pour cet identifiant'], 404);
        }

        if ($otp->expires_at->isPast()) {
            return response()->json(['error' => 'Le code a expiré'], 403);
        }

        if ($otp->attempts >= 3) {
            return response()->json(['error' => 'Trop de tentatives. Veuillez demander un nouveau code.'], 403);
        }

        if ($otp->code !== $reqCode) {
            $otp->increment('attempts');
            return response()->json(['error' => 'Code invalide'], 403);
        }

        $otp->update(['verified_at' => Carbon::now()]);

        // Mettre à jour l'utilisateur si existant
        $user = User::where('email', $identifier)->orWhere('phone', $identifier)->first();
        if ($user) {
            if ($type === 'email') {
                $user->email_verified_at = Carbon::now();
            } else {
                // Si vous avez un champ pour le téléphone, sinon on peut utiliser le même ou un autre champ
                 $user->email_verified_at = Carbon::now(); // On considère que la verif valide le compte
            }
            $user->save();
        }

        return response()->json(['message' => 'Code vérifié avec succès']);
    }

    public function register(RegisterRequest $request)
    {
        // Validation automatique via RegisterRequest
        
        $email = $request->email ? trim($request->email) : null;
        $phone = $request->phone ? trim($request->phone) : null;
        $type = $email ? 'email' : 'phone';

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
            'is_agency' => $request->is_agency ?? false,
            // Prestataires need admin validation
            'is_validated' => $request->role === 'prestataire' ? false : true,
            'email_verified_at' => null, // OTP après inscription
        ]);


        // Attacher les professions si elles existent
        if ($request->has('profession_ids')) {
            $user->professions()->sync($request->profession_ids);
        }

        // Gérer les professions personnalisées (bouton Autre)
        if ($request->has('custom_professions')) {
            $customIds = [];
            foreach ($request->custom_professions as $profName) {
                // Nettoyer le nom (trim, title case)
                $cleanName = Str::title(trim($profName));
                
                // Trouver ou créer la profession
                $profession = \App\Models\Profession::firstOrCreate(
                    ['name' => $cleanName]
                );
                
                $customIds[] = $profession->id;
            }
            
            // Attacher sans détacher les précédents
            if (!empty($customIds)) {
                $user->professions()->attach($customIds);
            }
        }

        // Création du token
        $token = $user->createToken('LaravelPassportToken')->accessToken;

        // Envoyer le code OTP
        $identifier = $email ?? $phone;
        $this->sendOtpInternal($identifier, $type);

        // Réponse JSON
        return response()->json([
            'message' => 'Utilisateur enregistré avec succès. Veuillez vérifier votre code OTP envoyé.',
            'require_verification' => true,
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
                'is_validated' => (bool) $user->is_validated,
                'is_agency' => (bool) $user->is_agency,
                'is_available' => (bool) $user->is_available,
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
        $credentials = [];
        if ($request->email) {
            $credentials = ['email' => $request->email, 'password' => $request->password];
        } else {
            $credentials = ['phone' => $request->phone, 'password' => $request->password];
        }
        
        if (! Auth::attempt($credentials)) {
            return response()->json(['error' => 'Identifiants invalides'], 401);
        }
        
        $user = Auth::user();
        
        $tokenResult = $user->createToken('LaravelPassportToken');
        $accessToken = $tokenResult->accessToken;

        $refreshToken = null;
        if ($request->remember_me) {
            $refreshToken = Str::random(60);
            UserRefreshToken::create([
                'user_id' => $user->id,
                'token' => $refreshToken,
                'expires_at' => Carbon::now()->addMonths(6),
            ]);
        }

        return response()->json([
            'message' => 'Connexion réussie',
            'user' => $user,
            'token' => $accessToken,
            'refresh_token' => $refreshToken,
        ]);
    }

    public function refreshToken(Request $request)
    {
        $request->validate([
            'refresh_token' => 'required|string',
        ]);

        $refreshTokenEntry = UserRefreshToken::where('token', $request->refresh_token)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$refreshTokenEntry) {
            return response()->json(['error' => 'Token de rafraîchissement invalide ou expiré'], 401);
        }

        $user = $refreshTokenEntry->user;
        $newAccessToken = $user->createToken('LaravelPassportToken')->accessToken;

        return response()->json([
            'token' => $newAccessToken,
        ]);
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

        return response()->json(['message' => 'Déconnexion réussie']);
    }

    // 🔹 Utilisateur connecté
    // UserController.php
    public function me(Request $request)
    {
        try {
            $user = $request->user()->load(['professions', 'competances']);
            return response()->json($user);
        } catch (\Exception $e) {
            \Log::error("Error in AuthController@me: " . $e->getMessage());
            return response()->json(['error' => 'Internal Server Error'], 500);
        }
    }

    public function updateAvailability(Request $request)
    {
        $request->validate([
            'is_available' => 'required|boolean',
        ]);

        $user = auth()->user();

        // 🛡️ SECURITY: Un prestataire ne peut pas passer en disponible si son solde est <= 0
        if ($request->is_available && $user->role === 'prestataire' && $user->balance <= 0) {
            return response()->json([
                'error' => 'Solde insuffisant',
                'message' => 'Votre portefeuille est vide. Veuillez recharger votre compte pour passer en disponible.',
                'balance' => (float) $user->balance
            ], 403);
        }

        $user->is_available = $request->is_available;
        $user->save();

        return response()->json([
            'message' => 'Disponibilité mise à jour',
            'is_available' => $user->is_available
        ]);
    }
}
