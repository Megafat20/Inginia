<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ProviderLocationUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $latitude;
    public $longitude;
    public $providerId;
    public $reservationId;

    public function __construct($providerId, $reservationId, $latitude, $longitude)
    {
        $this->providerId = $providerId;
        $this->reservationId = $reservationId;
        $this->latitude = $latitude;
        $this->longitude = $longitude;
    }

    public function broadcastOn()
    {
        // Canal privé sécurisé unique à la réservation
        return new PrivateChannel('reservation.' . $this->reservationId);
    }

    public function broadcastAs()
    {
        return 'provider.moved';
    }
}
