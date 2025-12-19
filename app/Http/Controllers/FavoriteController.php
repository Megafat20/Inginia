<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function toggle($providerId) {
        $user = auth()->user();
        $exists = $user->favorites()->where('provider_id', $providerId)->exists();
        if ($exists) {
            $user->favorites()->detach($providerId);
            return response()->json(['favorited' => false]);
        } else {
            $user->favorites()->attach($providerId);
            return response()->json(['favorited' => true]);
        }
    }

    public function list() {
        $user = auth()->user();
        $favorites = $user->favorites()->with('professions')->get();
        return response()->json($favorites);
    }
}
