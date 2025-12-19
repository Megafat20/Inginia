<?php

namespace App\Console\Commands;

use App\Models\Reservation;
use Illuminate\Console\Command;

class CompleteReservations extends Command
{
    protected $signature = 'reservations:complete';
    protected $description = 'Marquer les réservations acceptées passées comme terminées';

    public function handle()
    {
        $updated = Reservation::where('status', 'accepted')
            ->where('requested_date', '<', now())
            ->update(['status' => 'completed']);

        $this->info("Réservations complétées : $updated");
    }
}