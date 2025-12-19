<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CrossOriginHeaders
{
    public function handle(Request $request, Closure $next)
    {
        $response = $next($request);

        // Autoriser le frontend à communiquer avec le backend
        $response->headers->set('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
        $response->headers->set('Cross-Origin-Embedder-Policy', 'unsafe-none');

        return $response;
    }
}
