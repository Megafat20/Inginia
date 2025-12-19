<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UrgentRequestCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $requestData;

    /**
     * Create a new event instance.
     * 
     * @param array $requestData contains {lat, lng, problem_type, user_id, description}
     */
    public function __construct(array $requestData)
    {
        $this->requestData = $requestData;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // Diffuser à tous les prestataires (Channel public pour commencer, ou Presence pour filtrer)
        return [
            new Channel('urgent-requests'),
        ];
    }

    public function broadcastAs()
    {
        return 'urgent.created';
    }
}
