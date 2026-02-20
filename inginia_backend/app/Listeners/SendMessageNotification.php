<?php

namespace App\Listeners;

use App\Events\MessageSent;
use App\Services\FcmService;
use App\Models\Reservation;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendMessageNotification
{
    protected $fcm;

    /**
     * Create the event listener.
     */
    public function __construct(FcmService $fcm)
    {
        $this->fcm = $fcm;
    }

    /**
     * Handle the event.
     */
    public function handle(MessageSent $event): void
    {
        $message = $event->message;
        $reservation = Reservation::with(['client', 'provider'])->find($message->reservation_id);
        
        if (!$reservation) return;

        $sender = $message->user;
        $recipient = $reservation->client_id === $message->sender_id 
            ? $reservation->provider 
            : $reservation->client;

        $tokens = $recipient->deviceTokens()->where('revoked', false)->pluck('token')->toArray();
        if (empty($tokens)) return;

        $body = $message->message;
        if (empty($body)) {
            if ($message->audio_url) {
                $body = "🎙️ Note vocale";
            } else if ($message->image_url) {
                $body = "🖼️ Photo";
            } else {
                $body = "Nouveau message";
            }
        }

        try {
            $this->fcm->sendToMultipleTokens($tokens, "💬 " . ($sender->name ?? "Utilisateur"), $body, [
                'type' => 'new_message',
                'reservation_id' => (string)$reservation->id,
                'sender_id' => (string)$sender->id,
                'sender_name' => $sender->name ?? "Utilisateur",
                'screen' => 'chat',
            ]);
        } catch (\Exception $e) {
            Log::error("FCM Error (MessageSent): " . $e->getMessage());
        }
    }
}
