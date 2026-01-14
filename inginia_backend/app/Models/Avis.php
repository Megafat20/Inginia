<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Avis extends Model
{
    use HasFactory;
    
    protected $table = 'avis';

    protected $fillable = [
        'client_id',
        'prestataire_id',
        'reservation_id',
        'note',
        'commentaire',
        'ponctualite',
        'qualite',
        'prix',
        'communication',
        'photos',
        'reponse_prestataire',
        'reponse_at',
        'verified',
        'helpful_count'
    ];

    protected $casts = [
        'photos' => 'array',
        'reponse_at' => 'datetime',
        'verified' => 'boolean',
        'helpful_count' => 'integer',
    ];

    protected $appends = ['average_criteria_rating'];

    // Relations
    public function client()
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function prestataire()
    {
        return $this->belongsTo(User::class, 'prestataire_id');
    }

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }

    // Accessors
    public function getAverageCriteriaRatingAttribute()
    {
        $criteria = array_filter([
            $this->ponctualite,
            $this->qualite,
            $this->prix,
            $this->communication
        ]);

        return count($criteria) > 0 ? round(array_sum($criteria) / count($criteria), 1) : $this->note;
    }

    // Scopes
    public function scopeVerified($query)
    {
        return $query->where('verified', true);
    }

    public function scopeWithPhotos($query)
    {
        return $query->whereNotNull('photos');
    }

    public function scopeByRating($query, $minRating)
    {
        return $query->where('note', '>=', $minRating);
    }
}
