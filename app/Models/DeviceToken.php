<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeviceToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'token',
        'platform',
        'user_agent',
        'timezone',
        'last_seen_at',
        'revoked',
    ];

    /**
     * Chaque token appartient à un utilisateur
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
