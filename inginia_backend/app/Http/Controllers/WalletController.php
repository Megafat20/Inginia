<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class WalletController extends Controller
{
    /**
     * Get wallet details (balance + transactions)
     */
    public function index()
    {
        $user = auth()->user();
        
        $transactions = \App\Models\Transaction::where('user_id', $user->id)
            ->latest()
            ->limit(20)
            ->get();

        return response()->json([
            'balance' => (float) $user->balance,
            'transactions' => $transactions
        ]);
    }

    /**
     * Process a recharge request
     */
    public function recharge(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:100',
            'provider' => 'required|string', // nita, orange, etc.
            'phone' => 'required|string',
        ]);

        $user = auth()->user();
        $amount = (float) $request->amount;
        $provider = $request->provider;
        
        // 🚨 SIMULATION MODE 🚨
        // In a real scenario, here we would call the Payment Gateway API (Nita/Orange/Stripe)
        // and waiting for a webhook callback.
        // For this implementation, we simulate an INSTANT SUCCESS.
        
        try {
            \Illuminate\Support\Facades\DB::beginTransaction();

            // 1. Create Transaction Record
            $transaction = \App\Models\Transaction::create([
                'user_id' => $user->id,
                'type' => 'credit',
                'amount' => $amount,
                'payment_method' => $provider,
                'status' => 'completed',
                'reference' => strtoupper(uniqid('TXN_')),
                'description' => "Recharge via " . ucfirst($provider) . " (Simulated)",
            ]);

            // 2. Update User Balance
            $user->balance += $amount;
            $user->save();

            // 3. ✅ Réactiver le prestataire (débloquer)
            if ($user->role === 'prestataire' && !$user->is_available) {
                $user->is_available = true;
                $user->save();
            }

            // 4. 💰 Payer les commissions en attente si possible
            $pendingCommissions = \App\Models\Transaction::where('user_id', $user->id)
                ->where('type', 'debit')
                ->where('payment_method', 'system')
                ->where('status', 'pending')
                ->get();

            foreach ($pendingCommissions as $pending) {
                if ($user->balance >= $pending->amount) {
                    $user->balance -= $pending->amount;
                    $pending->update(['status' => 'completed']);
                }
            }
            $user->save();

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'message' => 'Recharge effectuée avec succès',
                'balance' => $user->balance,
                'transaction' => $transaction,
                'is_available' => $user->is_available ?? true
            ]);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json(['error' => 'Erreur lors de la transaction'], 500);
        }
    }
}
