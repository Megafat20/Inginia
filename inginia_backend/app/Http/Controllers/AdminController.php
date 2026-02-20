<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\ProviderValidation;
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
            ->with(['professions', 'portfolios'])
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
                    'portfolios' => $user->portfolios->map(fn ($item) => [
                        'id' => $item->id,
                        'title' => $item->title,
                        'description' => $item->description,
                        'image_url' => asset('storage/'.$item->image_path),
                    ]),
                    'validation_expires_at' => $user->validation_expires_at,
                    'validation_comment' => $user->validation_comment,
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
            ->with(['professions', 'portfolios'])
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
                    'portfolios' => $user->portfolios->map(fn ($item) => [
                        'id' => $item->id,
                        'title' => $item->title,
                        'description' => $item->description,
                        'image_url' => asset('storage/'.$item->image_path),
                    ]),
                    'validation_expires_at' => $user->validation_expires_at,
                    'validation_comment' => $user->validation_comment,
                    'validation_history' => $user->providerValidations()->with('admin:id,name')->latest()->get(),
                ];
            });

        return response()->json($validatedProviders);
    }

    /**
     * Validate a provider
     */
    public function validateProvider(Request $request, $id)
    {
        $request->validate([
            'comment' => 'nullable|string',
            'expires_at' => 'nullable|date|after:now',
        ]);

        $provider = User::where('id', $id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        \Illuminate\Support\Facades\DB::beginTransaction();
        try {
            $provider->is_validated = true;
            $provider->validation_comment = $request->comment;
            $provider->validation_expires_at = $request->expires_at;
            $provider->save();

            // Store history
            ProviderValidation::create([
                'user_id' => $provider->id,
                'status' => 'validated',
                'comment' => $request->comment,
                'expires_at' => $request->expires_at,
                'admin_id' => auth()->id(),
            ]);

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'message' => 'Prestataire validé avec succès',
                'provider' => $provider
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json(['error' => 'Erreur lors de la validation'], 500);
        }
    }

    /**
     * Reject a provider registration
     */
    public function rejectProvider(Request $request, $id)
    {
        $request->validate([
            'comment' => 'required|string',
        ]);

        $provider = User::where('id', $id)
            ->where('role', 'prestataire')
            ->firstOrFail();

        \Illuminate\Support\Facades\DB::beginTransaction();
        try {
            // Store history before (maybe) deleting or just deactivating
            ProviderValidation::create([
                'user_id' => $provider->id,
                'status' => 'rejected',
                'comment' => $request->comment,
                'admin_id' => auth()->id(),
            ]);

            // Instead of deleting, we might want to just keep it as unvalidated with a comment
            // or delete it as originally requested. 
            // The checklist says "Approuver/Rejeter + commentaire". 
            // If we delete, we lose history unless we keep a record.
            
            // To keep history, we shouldn't delete the user immediately if we want to show it in admin lists.
            // But if the request was "The account will be deleted" (originally), I'll stick to deletion but AFTER storing history.
            // Wait, provider_validations has a FK to users. If I delete user, history is gone (onDelete cascade).
            
            // Re-evaluating: Rejection should probably NOT delete the user if we want history.
            // I'll change it to set is_validated = false and store the comment.
            
            $provider->is_validated = false;
            $provider->validation_comment = $request->comment;
            $provider->save();

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'message' => 'Prestataire rejeté avec commentaire'
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json(['error' => 'Erreur lors du rejet'], 500);
        }
    }

    /**
     * Get dashboard statistics
     */
    public function getDashboardStats(Request $request)
    {
        $period = $request->get('period', 'month'); // day, week, month, year

        // 1. Définir les dates
        $now = now();
        $startDate = match($period) {
            'day' => $now->copy()->startOfDay(),
            'week' => $now->copy()->startOfWeek(),
            'month' => $now->copy()->startOfMonth(),
            'year' => $now->copy()->startOfYear(),
            default => $now->copy()->startOfMonth(),
        };
        
        $endDate = $now->copy()->endOfDay();

        $previousStartDate = match($period) {
            'day' => $startDate->copy()->subDay(),
            'week' => $startDate->copy()->subWeek(),
            'month' => $startDate->copy()->subMonth(),
            'year' => $startDate->copy()->subYear(),
            default => $startDate->copy()->subMonth(),
        };

        $previousEndDate = match($period) {
            'day' => $endDate->copy()->subDay(),
            'week' => $endDate->copy()->subWeek(),
            'month' => $endDate->copy()->subMonth(),
            'year' => $endDate->copy()->subYear(),
            default => $endDate->copy()->subMonth(),
        };

        // 2. Helper pour Variations
        $getVariation = function ($current, $previous) {
            if ($previous == 0) return $current > 0 ? 100 : 0;
            return round((($current - $previous) / $previous) * 100, 1);
        };

        // 3. KPIs
        $currentUsers = User::whereBetween('created_at', [$startDate, $endDate])->count();
        $previousUsers = User::whereBetween('created_at', [$previousStartDate, $previousEndDate])->count();
        $totalUsers = User::count();

        $currentMissions = \App\Models\Reservation::whereBetween('created_at', [$startDate, $endDate])->count();
        $previousMissions = \App\Models\Reservation::whereBetween('created_at', [$previousStartDate, $previousEndDate])->count();
        $totalMissions = \App\Models\Reservation::count();

        $currentRevenue = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'system')
            ->where('status', 'completed')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->sum('amount');
        
        $previousRevenue = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'system')
            ->where('status', 'completed')
            ->whereBetween('created_at', [$previousStartDate, $previousEndDate])
            ->sum('amount');

        $currentRating = \App\Models\Avis::whereBetween('created_at', [$startDate, $endDate])->avg('note') ?? 0;
        $previousRating = \App\Models\Avis::whereBetween('created_at', [$previousStartDate, $previousEndDate])->avg('note') ?? 0;
        $globalRating = \App\Models\Avis::avg('note') ?? 0;

        // 4. Chart Data
        $pgFormat = ($period === 'year') ? 'YYYY-MM' : 'YYYY-MM-DD';
        
        // Revenue Chart Data
        $revenueDetails = \App\Models\Transaction::where('type', 'debit')
            ->where('payment_method', 'system')
            ->where('status', 'completed')
            ->where('created_at', '>=', $startDate)
            ->select(
                \Illuminate\Support\Facades\DB::raw("TO_CHAR(created_at, '$pgFormat') as date"),
                \Illuminate\Support\Facades\DB::raw('SUM(amount) as total')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Users Growth Chart Data
        $usersGrowth = User::where('created_at', '>=', $startDate)
            ->select(
                \Illuminate\Support\Facades\DB::raw("TO_CHAR(created_at, '$pgFormat') as date"),
                \Illuminate\Support\Facades\DB::raw('COUNT(*) as count')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // 5. Alerts
        $pendingProviders = User::where('role', 'prestataire')->where('is_validated', false)->count();
        $pendingReports = \App\Models\Report::where('status', 'pending')->count();

        // 6. Missions by Category for Chart
        $missionsByCategory = \App\Models\Reservation::with('competance') // competence -> service -> category (via relations)
            ->where('created_at', '>=', $startDate)
            ->get()
            ->groupBy(function($item) {
                // Assuming competance is the service, and we want to group by service name
                return $item->competance->name ?? 'Autre';
            })
            ->map(function($group) {
                return $group->count();
            });
            
        // Transform for frontend {name: 'Cat', value: 10}
        $missionsChartData = [];
        foreach($missionsByCategory as $key => $value) {
            $missionsChartData[] = ['name' => $key, 'value' => $value];
        }

        $stats = [
            'kpi' => [
                'users' => [
                    'total' => $totalUsers,
                    'variation' => $getVariation($currentUsers, $previousUsers),
                ],
                'missions' => [
                    'total' => $totalMissions,
                    'variation' => $getVariation($currentMissions, $previousMissions),
                ],
                'revenue' => [
                    'total' => $currentRevenue,
                    'variation' => $getVariation($currentRevenue, $previousRevenue),
                ],
                'rating' => [
                    'average' => round($globalRating, 1),
                    'variation' => $getVariation($currentRating, $previousRating),
                ],
            ],
            'charts' => [
                'revenue' => $revenueDetails,
                'missions_by_category' => $missionsChartData,
                'users_active' => $usersGrowth,
            ],
            'alerts' => [
                'pending_providers' => $pendingProviders,
                'pending_reports' => $pendingReports,
            ],
            // Backward compatibility
            'total_users' => $totalUsers,
            'total_clients' => User::where('role', 'client')->count(),
            'total_providers' => User::where('role', 'prestataire')->count(),
            'pending_providers' => $pendingProviders,
            'validated_providers' => User::where('role', 'prestataire')->where('is_validated', true)->count(),
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
                    'is_active' => $user->is_active,
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
     * Toggle User Active Status (Admin)
     */
    public function toggleActiveStatus($id)
    {
        $user = User::findOrFail($id);
        $user->is_active = !$user->is_active;
        $user->save();

        return response()->json([
            'message' => $user->is_active ? 'Utilisateur activé' : 'Utilisateur désactivé',
            'is_active' => $user->is_active
        ]);
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
