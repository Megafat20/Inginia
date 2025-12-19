<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'provider_id',   // utilisateur qui propose le service (prestataire ou agence)
        'profession_id', // rattachement à une profession
        'price',
    ];

    /**
     * 🔗 Relation avec l'utilisateur (prestataire ou agence)
     */
    public function provider()
    {
        return $this->belongsTo(User::class, 'provider_id');
    }

    /**
     * 🔗 Relation avec la profession
     */
    public function profession()
    {
        return $this->belongsTo(Profession::class);
    }

    /**
     * 🔗 Relation avec les réservations de ce service
     */
    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }
}
