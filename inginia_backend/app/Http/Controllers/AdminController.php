<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    /**
     * Get all pending provider registrations
     */
    public function getPendingProviders()
    {
        $pendingProviders = User::where('role', 'prestataire')
            ->where('is_validated', false)
            ->with('professions')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'service' => $user->service,
                    'is_agency' => $user->is_agency,
                    'location' => $user->location,
                    'adresse' => $user->adresse,
                    'min_price' => $user->min_price,
                    'slogan' => $user->slogan,
                    'created_at' => $user->created_at,
                    'profile_photo' => $user->photo 
                        ? asset('storage/profile_photos/'.$user->photo) 
                        : null,
                    'professions' => $user->professions->map(fn ($p) => [
                        'id' => $p->id,
                        'name' => $p->name,
                    ]),
                ];
            });

        return response()->json($pendingProviders);
    }

    /**
     * Get all validated providers
     */
    public function getValidatedProviders()
    {
        $validatedProviders = User::where('role', 'prestataire')
            ->where('is_validated', true)
            ->with('professions')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'service' => $user->service,
                    'is_agency' => $user->is_agency,
                    'location' => $user->location,
                    'min_price' => $user->min_price,
                    'slogan' => $user->slogan,
                    'created_at' => $user->created_at,
                    'profile_photo' => $user->photo 
                        ? asset('storage/profile_photos/'.$user->photo) 
                        : null,
                    'professions' => $user->professions->map(fn ($p) => [
                        'id' => $p->id,
                        'name' => $p->name,
                    ]),
                ];
            });

        return response()->json($validatedProviders);
    }

    /**
     * Validate a provider
     */
    public function validateProvider(Request $request, $id)
    {
        $provider = User::where('id', $id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        $provider->is_validated = true;
        $provider->save();

        return response()->json([
            'message' => 'Prestataire validé avec succès',
            'provider' => $provider
        ]);
    }

    /**
     * Reject a provider registration
     */
    public function rejectProvider(Request $request, $id)
    {
        $provider = User::where('id', $id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        // Optional: Send notification before deletion
        $provider->delete();

        return response()->json([
            'message' => 'Prestataire rejeté et supprimé'
        ]);
    }

    /**
     * Get dashboard statistics
     */
    public function getDashboardStats()
    {
        $stats = [
            'total_users' => User::count(),
            'total_clients' => User::where('role', 'client')->count(),
            'total_providers' => User::where('role', 'prestataire')->count(),
            'pending_providers' => User::where('role', 'prestataire')
                ->where('is_validated', false)
                ->count(),
            'validated_providers' => User::where('role', 'prestataire')
                ->where('is_validated', true)
                ->count(),
            'total_agencies' => User::where('is_agency', true)->count(),
        ];

        return response()->json($stats);
    }

    /**
     * Get all users (for admin management)
     */
    public function getAllUsers(Request $request)
    {
        $users = User::with('professions')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'role' => $user->role,
                    'service' => $user->service,
                    'is_agency' => $user->is_agency,
                    'is_validated' => $user->is_validated,
                    'location' => $user->location,
                    'created_at' => $user->created_at,
                    'profile_photo' => $user->photo 
                        ? asset('storage/profile_photos/'.$user->photo) 
                        : null,
                ];
            });

        return response()->json($users);
    }
}
