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

        $sender = $message->sender;
        $recipient = $reservation->client_id === $message->sender_id 
            ? $reservation->provider 
            : $reservation->client;

        if (!$recipient) return;

        $tokens = $recipient->deviceTokens()->where('revoked', false)->pluck('token')->toArray();
        if (empty($tokens)) return;

        try {
            $this->fcm->sendToMultipleTokens(
                $tokens,
                "Message de " . ($sender->name ?? "Utilisateur"),
                $message->message,
                [
                    'type' => 'chat',
                    'reservation_id' => (string)$reservation->id,
                    'sender_name' => $sender->name ?? "Utilisateur",
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                ]
            );
        } catch (\Exception $e) {
            Log::error("FCM Error (MessageSent): " . $e->getMessage());
        }
    }
}
