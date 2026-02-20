<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ClientLocationUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $latitude;
    public $longitude;
    public $clientId;
    public $reservationId;

    public function __construct($clientId, $reservationId, $latitude, $longitude)
    {
        $this->clientId = $clientId;
        $this->reservationId = $reservationId;
        $this->latitude = $latitude;
        $this->longitude = $longitude;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('reservation.' . $this->reservationId);
    }

    public function broadcastAs()
    {
        return 'client.moved';
    }
}
