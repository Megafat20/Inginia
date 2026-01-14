<?php

namespace App\Listeners;

use App\Events\ReservationCreated;
use App\Services\FcmService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendReservationCreatedNotification
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
    public function handle(ReservationCreated $event): void
    {
        $reservation = $event->reservation;
        $provider = $reservation->provider;
        $client = $reservation->client;

        if (!$provider || !$client) return;

        $tokens = $provider->deviceTokens()->where('revoked', false)->pluck('token')->toArray();

        if (empty($tokens)) return;

        try {
            $this->fcm->sendToMultipleTokens(
                $tokens,
                "Nouvelle demande ! 🛠️",
                "{$client->name} a besoin de vos services.",
                [
                    'type' => 'reservation',
                    'reservation_id' => (string)$reservation->id,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                ]
            );
        } catch (\Exception $e) {
            Log::error("FCM Error (ReservationCreated): " . $e->getMessage());
        }
    }
}
