<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'reservation_id', 
        'sender_id',
        'message',
        'image_url',
        'audio_url',
    ];

    public function user() {
        return $this->belongsTo(User::class,'sender_id');
    }

    public function reservation() {
        return $this->belongsTo(Reservation::class);
    }
}
