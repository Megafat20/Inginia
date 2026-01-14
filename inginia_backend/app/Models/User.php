<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Passport\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'role',
        'photo',
        'location',
        'adresse',
        'slogan',
        'min_price',
        'latitude',
        'longitude',
        'service',
        'is_validated',
        'is_agency',
        'is_available',
        'google_id',
        'fcm_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_validated' => 'boolean',
        'is_agency' => 'boolean',
        'is_available' => 'boolean',
    ];

    // 🔹 Services proposés par le provider
    public function competances()
    {
        return $this->hasMany(Service::class, 'provider_id');
    }

    // 🔹 Réservations faites en tant que client
    public function reservations()
    {
        return $this->hasMany(Reservation::class, 'provider_id');
    }

    // 🔹 Réservations reçues en tant que prestataire ou agence
    public function receivedReservations()
    {
        return $this->hasMany(Reservation::class, 'provider_id');
    }

    // 🔹 Professions liées via pivot
    public function professions()
    {
        return $this->belongsToMany(Profession::class, 'prestataire_professions', 'prestataire_id', 'profession_id');
    }

    // 🔹 Avis reçus
    public function reviewsReceived()
    {
        return $this->hasMany(Avis::class, 'prestataire_id');
    }

    // 🔹 Portfolio de réalisations
    public function portfolios()
    {
        return $this->hasMany(Portfolio::class, 'provider_id');
    }

    // 🔹 Note moyenne calculée
    public function getAverageRatingAttribute()
    {
        return $this->reviewsReceived()->avg('note') ?? 0;
    }

    public function completedServices()
    {
        return $this->hasMany(Reservation::class, 'provider_id')
            ->where('status', 'completed');
    }

    public function favorites()
    {
        return $this->belongsToMany(User::class, 'favorites', 'user_id', 'provider_id');
    }

    // Prestataire
    public function favoritedBy()
    {
        return $this->belongsToMany(User::class, 'favorites', 'provider_id', 'user_id');
    }
    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function availabilities()
    {
        return $this->hasMany(Availability::class);
    }

    public function scopeAvecDistance($query, $lat, $lng)
    {
        $haversine = "(6371 * acos(cos(radians($lat)) 
                * cos(radians(latitude)) 
                * cos(radians(longitude) - radians($lng)) 
                + sin(radians($lat)) 
                * sin(radians(latitude))))";

        return $query->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->select('*')
            ->selectRaw("$haversine AS distance")
            ->orderBy('distance', 'asc'); // tri uniquement par distance
    }



}
