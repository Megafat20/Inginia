<?php

namespace App\Http\Controllers;

use App\Models\DeviceToken;
use Illuminate\Http\Request;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\WebPushConfig;

class DeviceTokenController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'token' => 'required|string',
            'platform' => 'nullable|in:web,android,ios',
        ]);
    
        $userId = $request->user()->id ?? null;
    
        // Si le token existe déjà, on met juste à jour l'utilisateur et last_seen
        $deviceToken = DeviceToken::updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $userId,
                'platform' => $data['platform'] ?? 'web',
                'user_agent' => $request->userAgent(),
                'timezone' => $request->header('X-Timezone') ?? null,
                'last_seen_at' => now(),
                'revoked' => false,
            ]
        );
    
        return response()->json(['status' => 'ok', 'deviceToken' => $deviceToken]);
    }
    

    public function unregister(Request $request)
    {
        $request->validate(['token' => 'required']);
        DeviceToken::where('token', $request->token)->delete();

        return response()->json(['status' => 'ok']);
    }

    public function test(Request $request, Messaging $messaging)
    {
        $request->validate([
            'token' => 'nullable|string',
            'user_id' => 'nullable|integer',
            'title' => 'nullable|string',
            'body'  => 'nullable|string',
            'link'  => 'nullable|url',
        ]);

        $tokens = collect();

        if ($request->filled('token')) {
            $tokens = collect([$request->token]);
        } elseif ($request->filled('user_id')) {
            $tokens = DeviceToken::where('user_id', $request->user_id)
                ->where('revoked', false)->pluck('token');
        }

        if ($tokens->isEmpty()) {
            return response()->json(['error' => 'Aucun token trouvé'], 422);
        }

        $title = $request->input('title', 'Notification de test');
        $body  = $request->input('body', 'Ça fonctionne !');
        $link  = $request->input('link', url('/notifications'));

        $message = CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withWebPushConfig(WebPushConfig::fromArray([
                'notification' => [
                    'icon' => '/icons/icon-192x192.png',
                ],
                'fcm_options' => [
                    'link' => $link,
                ],
            ]));

        // Envoi en multicast (chunk par sécurité)
        $tokens->chunk(500)->each(function ($chunk) use ($messaging, $message) {
            $messaging->sendMulticast($message, $chunk->all());
        });

        return response()->json(['sent' => $tokens->count()]);
    }
}
