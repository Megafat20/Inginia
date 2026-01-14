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
                    'latitude' => $user->latitude,
                    'longitude' => $user->longitude,
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
                    'adresse' => $user->adresse,
                    'latitude' => $user->latitude,
                    'longitude' => $user->longitude,
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
    /**
     * Update a user (Admin)
     */
    public function updateUser(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users,email,' . $id,
            'role' => 'required|in:client,prestataire,admin',
            'phone' => 'nullable|string',
            'is_validated' => 'boolean',
            'is_agency' => 'boolean',
        ]);

        $user->update($request->all());

        return response()->json([
            'message' => 'Utilisateur mis à jour avec succès',
            'user' => $user
        ]);
    }

    /**
     * Delete a user (Admin)
     */
    public function deleteUser($id)
    {
        $user = User::findOrFail($id);
        $user->delete();

        return response()->json([
            'message' => 'Utilisateur supprimé avec succès'
        ]);
    }

    /**
     * 💰 Vue d'ensemble des portefeuilles (Admin Dashboard)
     */
    public function getWalletOverview()
    {
        $stats = [
            'total_balance' => \App\Models\User::where('role', 'prestataire')->sum('balance'),
            'total_commissions' => \App\Models\Transaction::where('type', 'debit')
                ->where('payment_method', 'system')
                ->where('status', 'completed')
                ->sum('amount'),
            'pending_commissions' => \App\Models\Transaction::where('type', 'debit')
                ->where('status', 'pending')
                ->sum('amount'),
            'total_recharges' => \App\Models\Transaction::where('type', 'credit')
                ->where('status', 'completed')
                ->sum('amount'),
            'providers_with_balance' => \App\Models\User::where('role', 'prestataire')
                ->where('balance', '>', 0)
                ->count(),
            'providers_negative_balance' => \App\Models\User::where('role', 'prestataire')
                ->where('balance', '<', 0)
                ->count(),
        ];

        return response()->json($stats);
    }

    /**
     * 📊 Toutes les transactions (avec filtres)
     */
    public function getAllTransactions(Request $request)
    {
        $query = \App\Models\Transaction::with('user:id,name,email,phone')
            ->latest();

        // Filtres optionnels
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        $transactions = $query->paginate(50);

        return response()->json($transactions);
    }

    /**
     * 👤 Portefeuille d'un prestataire spécifique
     */
    public function getProviderWallet($id)
    {
        $provider = User::where('id', $id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        $transactions = \App\Models\Transaction::where('user_id', $provider->id)
            ->latest()
            ->get();

        $stats = [
            'balance' => $provider->balance,
            'total_credits' => $transactions->where('type', 'credit')->sum('amount'),
            'total_debits' => $transactions->where('type', 'debit')->sum('amount'),
            'pending_debits' => $transactions->where('type', 'debit')
                ->where('status', 'pending')
                ->sum('amount'),
        ];

        return response()->json([
            'provider' => [
                'id' => $provider->id,
                'name' => $provider->name,
                'email' => $provider->email,
                'phone' => $provider->phone,
            ],
            'stats' => $stats,
            'transactions' => $transactions,
        ]);
    }

    /**
     * ⚙️ Ajustement manuel du solde (Admin uniquement)
     */
    public function adjustBalance(Request $request, $userId)
    {
        $request->validate([
            'amount' => 'required|numeric',
            'type' => 'required|in:credit,debit',
            'reason' => 'required|string|max:500',
        ]);

        $user = User::findOrFail($userId);
        $amount = abs($request->amount);

        \Illuminate\Support\Facades\DB::beginTransaction();

        try {
            // Ajuster le solde
            if ($request->type === 'credit') {
                $user->balance += $amount;
            } else {
                $user->balance -= $amount;
            }
            $user->save();

            // Créer la transaction
            \App\Models\Transaction::create([
                'user_id' => $user->id,
                'type' => $request->type,
                'amount' => $amount,
                'status' => 'completed',
                'payment_method' => 'admin_adjustment',
                'reference' => 'ADJ_' . time(),
                'description' => "Ajustement Admin: " . $request->reason,
            ]);

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'message' => 'Solde ajusté avec succès',
                'new_balance' => $user->balance,
            ]);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json(['error' => 'Erreur lors de l\'ajustement'], 500);
        }
    }

    /**
     * 📈 Statistiques des commissions
     */
    public function getCommissionStats(Request $request)
    {
        $period = $request->get('period', 'month'); // day, week, month, year

        $dateFilter = match($period) {
            'day' => now()->startOfDay(),
            'week' => now()->startOfWeek(),
            'month' => now()->startOfMonth(),
            'year' => now()->startOfYear(),
            default => now()->startOfMonth(),
        };

        $commissions = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'system')
            ->where('created_at', '>=', $dateFilter)
            ->get();

        $stats = [
            'period' => $period,
            'total_commissions' => $commissions->where('status', 'completed')->sum('amount'),
            'pending_commissions' => $commissions->where('status', 'pending')->sum('amount'),
            'transaction_count' => $commissions->where('status', 'completed')->count(),
            'average_commission' => $commissions->where('status', 'completed')->avg('amount'),
            'top_providers' => \App\Models\Transaction::where('type', 'debit')
                ->where('payment_method', 'system')
                ->where('status', 'completed')
                ->where('created_at', '>=', $dateFilter)
                ->select('user_id', \Illuminate\Support\Facades\DB::raw('SUM(amount) as total'))
                ->groupBy('user_id')
                ->orderBy('total', 'desc')
                ->limit(10)
                ->with('user:id,name,email')
                ->get(),
        ];

        return response()->json($stats);
    }

    /**
     * 💰 Retrait des commissions par l'admin (vers compte Nita)
     */
    public function collectCommissions(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1000',
            'payment_method' => 'required|in:nita,orange,airtel',
            'account_number' => 'required|string',
        ]);

        $amount = (float) $request->amount;

        // Calculer le total des commissions disponibles
        $totalCommissions = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'system')
            ->where('status', 'completed')
            ->sum('amount');

        // Calculer ce qui a déjà été retiré
        $alreadyCollected = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'admin_collection')
            ->where('status', 'completed')
            ->sum('amount');

        $availableCommissions = $totalCommissions - $alreadyCollected;

        if ($amount > $availableCommissions) {
            return response()->json([
                'error' => 'Montant supérieur aux commissions disponibles',
                'available' => $availableCommissions,
                'requested' => $amount
            ], 400);
        }

        try {
            // Créer une transaction de collecte admin
            $collection = \App\Models\Transaction::create([
                'user_id' => auth()->id(), // Admin user
                'type' => 'debit',
                'amount' => $amount,
                'payment_method' => 'admin_collection',
                'status' => 'completed',
                'reference' => strtoupper(uniqid('COLLECT_')),
                'description' => "Retrait commissions Inginia vers " . strtoupper($request->payment_method) . " (" . $request->account_number . ")",
            ]);

            return response()->json([
                'message' => 'Collecte de commissions enregistrée',
                'collection' => $collection,
                'remaining_commissions' => $availableCommissions - $amount
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => 'Erreur lors de la collecte'], 500);
        }
    }

    /**
     * 📊 Historique des collectes de commissions
     */
    public function getCollectionHistory()
    {
        $collections = \App\Models\Transaction::where('payment_method', 'admin_collection')
            ->where('status', 'completed')
            ->latest()
            ->get();

        $totalCollected = $collections->sum('amount');

        $totalCommissions = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'system')
            ->where('status', 'completed')
            ->sum('amount');

        return response()->json([
            'collections' => $collections,
            'total_collected' => $totalCollected,
            'total_commissions' => $totalCommissions,
            'available_to_collect' => $totalCommissions - $totalCollected
        ]);
    }
}
