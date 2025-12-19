<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Google_Client;

class GoogleController extends Controller
{
    public function loginWithGoogle(Request $request)
    {
        $credential = $request->input('credential');
    
        try {
            $client = new Google_Client(['client_id' => env('GOOGLE_CLIENT_ID')]);
            $payload = $client->verifyIdToken($credential);
    
            if (!$payload) {
                return response()->json(['error' => 'Token Google invalide'], 401);
            }
    
            $user = User::firstOrCreate(
                ['email' => $payload['email']],
                [
                    'name' => $payload['name'] ?? '',
                    'google_id' => $payload['sub'],
                    'password' => bcrypt(bin2hex(random_bytes(16)))
                ]
            );
    
            $tokenResult = $user->createToken('authToken'); // Passport
            $token = $tokenResult->accessToken;   
            return response()->json([
                'token' => $token,
                'user' => $user
            ]);
    
        } catch (\Exception $e) {
            \Log::error($e->getMessage());
            return response()->json(['error' => 'Erreur serveur'], 500);
        }
    }
}
