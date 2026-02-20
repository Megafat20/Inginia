<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProviderValidation extends Model
{
    protected $fillable = [
        'user_id',
        'status',
        'comment',
        'expires_at',
        'admin_id',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
