<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Portfolio extends Model
{
    use HasFactory;

    protected $fillable = [
        'provider_id',
        'reservation_id',
        'image_path',
        'title',
        'description',
        'type',
    ];

    public function provider()
    {
        return $this->belongsTo(User::class, 'provider_id');
    }

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }
}
