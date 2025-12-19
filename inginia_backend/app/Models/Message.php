<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'reservation_id', // <-- utilise reservation au lieu de conversation
        'sender_id',
        'message',
    ];

    public function user() {
        return $this->belongsTo(User::class,'sender_id');
    }

    public function reservation() {
        return $this->belongsTo(Reservation::class);
    }
}
