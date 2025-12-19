<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authenticate extends Middleware
{
    /**
     * Get the path the user should be redirected to when they are not authenticated.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return string|null
     */
    protected function redirectTo($request)
    {
        // Pour les requêtes API, retourner null
        if ($request->expectsJson()) {
            return null;
        }
    
        // Sinon (ex: route web), tu peux rediriger vers ton frontend
        return env('FRONT_URL', 'http://localhost:3000/login');
    }
}
