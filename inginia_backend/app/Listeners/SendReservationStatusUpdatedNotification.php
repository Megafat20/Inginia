<?php

namespace App\Listeners;

use App\Events\ReservationStatusUpdated;
use App\Services\FcmService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendReservationStatusUpdatedNotification
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
    public function handle(ReservationStatusUpdated $event): void
    {
        $reservation = $event->reservation;
        $user = auth()->user(); // The one who made the change

        // Recipient is the other party
        $recipient = ($user && $user->id === $reservation->client_id) 
            ? $reservation->provider 
            : $reservation->client;
        
        if (!$recipient) return;

        $tokens = $recipient->deviceTokens()->where('revoked', false)->pluck('token')->toArray();
        if (empty($tokens)) return;

        $body = match ($reservation->status) {
            'accepted' => "Votre réservation a été acceptée ! ✅",
            'declined' => "La réservation a été déclinée. ❌",
            'in_progress' => "L'intervention a commencé. 🚀",
            'completed' => "L'intervention est terminée. ⭐",
            'cancelled' => "La réservation a été annulée. Motif : " . ($reservation->cancellation_reason ?? 'Non précisé'),
            default => "Le statut de votre réservation a changé : " . $reservation->status,
        };

        try {
            $this->fcm->sendToMultipleTokens(
                $tokens,
                "Suivi de mission 📋",
                $body,
                [
                    'type' => 'reservation_status',
                    'reservation_id' => (string)$reservation->id,
                    'status' => $reservation->status,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                ]
            );
        } catch (\Exception $e) {
            Log::error("FCM Error (ReservationStatusUpdated): " . $e->getMessage());
        }
    }
}
