<?php

namespace App\Http\Controllers;

use App\Models\Profession;
use App\Models\User;
use Illuminate\Http\Request;
use Symfony\Component\Process\Process;
use Symfony\Component\Process\Exception\ProcessFailedException;

class HomeController extends Controller
{
    public function getCategories()
    {
        $categories = Profession::withCount([
            'prestataires' => function ($query) {
                $query->whereIn('role', ['prestataire', 'service']);
            }
        ])
            ->orderByDesc('prestataires_count')
            ->take(15)
            ->get();

        return response()->json($categories);
    }

    public function getPopularProviders()
    {
        $providers = User::whereIn('role', ['prestataire', 'service'])
            ->with('professions')
            ->orderByDesc('rating') // si tu as un champ note pour les évaluations
            ->take(10) // top 10 par exemple
            ->get();

        return response()->json($providers);
    }
    public function getProvidersByCategory($categoryId)
    {
        $category = \DB::table('professions')->where('id', $categoryId)->first();

        if (!$category) {
            return response()->json([
                'error' => 'Catégorie introuvable'
            ], 404);
        }

        $providers = User::whereIn('role', ['prestataire', 'service'])
            ->whereHas('professions', function ($query) use ($categoryId) {
                $query->where('professions.id', $categoryId);
            })
            ->with('professions')
            ->withCount('reviewsReceived')
            ->orderByDesc('rating')
            ->get();

        return response()->json([
            'category' => $category, // 🔹 on renvoie le nom et l'id
            'providers' => $providers
        ]);
    }

    // HomeController.php
    public function search(Request $request)
    {
        $query = $request->get('query', '');
        $lat = $request->get('latitude');
        $lng = $request->get('longitude');
    
        if (!$query) {
            return response()->json([
                'providers' => [],
            ]);
        }
    
        $providers = User::where('role', 'prestataire')
            ->where(function ($q) use ($query) {
                $q->where('name', 'ilike', "%$query%")
                  ->orWhereHas('professions', function ($q2) use ($query) {
                      $q2->where('name', 'ilike', "%$query%");
                  })
                  ->orWhere('service', 'ilike', "%$query%");
            })
            ->with('professions')
            ->withCount('reviewsReceived');
    
        if ($lat && $lng) {
            $providers = $providers->avecDistance($lat, $lng);
        }
    
        $providers = $providers->take(20)->get()->map(function($p) {
            $p->is_new = $p->created_at > now()->subDays(7);
            return $p;
        });
    
        return response()->json([
            'providers' => $providers,
        ]);
    }
    

    public function recommanderPrestataires(Request $request)
    {
        $lat = $request->latitude;
        $lng = $request->longitude;
        $besoin = $request->besoin;
    
        $prestataires = User::where('role', 'prestataire')->with('professions')
        ->when($besoin, function ($query) use ($besoin) {
            $query->whereHas('professions', function ($q) use ($besoin) {
                $q->where('name', 'LIKE', "%$besoin%");
            });
        });
    
    
        if ($lat && $lng) {
            $prestataires = $prestataires->avecDistance($lat, $lng);
        }
    
        return response()->json($prestataires->take(10)->get());
    }
    


}
