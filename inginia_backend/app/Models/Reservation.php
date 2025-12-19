<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reservation extends Model
{
    use HasFactory;
    protected $fillable = [
        'client_id',
        'provider_id',
        'requested_date',
        'proposed_date',
        'status',
        'service_id',
        'commentaire', 
        'other_service',
        'client_lat',
        'client_lng',
        'provider_lat',
        'provider_lng',
    ];
    public function competance()
    {
        return $this->belongsTo(Service::class, 'service_id');
    }

    public function client()
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function provider()
    {
        return $this->belongsTo(User::class, 'provider_id');
    }
}
