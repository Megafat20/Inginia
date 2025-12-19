<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Profession extends Model
{
    use HasFactory;

    public function prestataires()
{
    return $this->belongsToMany(User::class, 'prestataire_professions', 'profession_id', 'prestataire_id');
}
}
