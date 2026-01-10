<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Portfolio extends Model
{
    use HasFactory;

    protected $fillable = [
        'provider_id',
        'image_path',
        'title',
        'description',
    ];

    public function provider()
    {
        return $this->belongsTo(User::class, 'provider_id');
    }
}
