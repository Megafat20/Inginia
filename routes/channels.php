<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});


Broadcast::channel('chat.{reservationId}', function ($user, $reservationId) {
    // Seul le client ou le prestataire de la réservation peut écouter le canal
    return \App\Models\Reservation::where('id', $reservationId)
            ->where(function($q) use ($user) {
                $q->where('client_id', $user->id)
                  ->orWhere('provider_id', $user->id);
            })->exists();
}); 