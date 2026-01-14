<?php

use App\Http\Controllers\GoogleController;
use App\Http\Controllers\AvisController;
use App\Http\Controllers\DeviceTokenController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\ProfessionController;
use App\Http\Controllers\ReservationController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProviderController;
use App\Services\FcmService;
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
//     return $request->user();
// });

// Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
//     Route::get('/admin/dashboard', [AdminController::class, 'index']);
// });


Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/auth/google', [GoogleController::class, 'loginWithGoogle']);
Route::get('/professions', [ProfessionController::class, 'index']);
Route::get('/categories', [HomeController::class, 'getCategories']);
Route::get('/providers/popular', [HomeController::class, 'getPopularProviders']);
Route::get('/providers/category/{id}', [HomeController::class, 'getProvidersByCategory']);
Route::get('/search', [HomeController::class, 'search']);
Route::middleware('auth:api')->group(function () {
    Route::get('/providers', [UserController::class, 'getProvidersAndServices']);

    
    

    Route::post('/prestataires/recommandes', [HomeController::class, 'recommanderPrestataires']);


    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::post('/me', [UserController::class, 'update']);
    Route::put('/me/password', [UserController::class, 'updatePassword']);

    Route::get('/avis/{prestataire_id}', [AvisController::class, 'show']);
    Route::post('/avis/{prestataire_id}', [AvisController::class, 'store']);
    Route::post('/avis/{avis_id}/respond', [AvisController::class, 'respond']);
    Route::post('/avis/{avis_id}/helpful', [AvisController::class, 'markHelpful']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me/availability', [AuthController::class, 'updateAvailability']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/users/fcm-token', [UserController::class, 'updateFcmToken']);

    Route::get('/provider/profile', [ProviderController::class, 'profile']);
    Route::get('/provider/stats', [ProviderController::class, 'getProviderStat']);
    Route::post('/provider/services', [ProviderController::class, 'addService']);
    Route::put('/provider/services/{id}', [ProviderController::class, 'updateService']);
    Route::delete('/provider/services/{id}', [ProviderController::class, 'deleteService']);
    Route::get('/provider/{id}/services', [ProviderController::class, 'getServicesByProviderId']);

    Route::get('/provider/{id}/dashboard', [ProviderController::class, 'getFullDashboard']);
    Route::get('/provider/myprofessions', [ProviderController::class, 'myProfessions']);
    
    // Portfolio
    Route::post('/provider/portfolio', [\App\Http\Controllers\Api\PortfolioController::class, 'store']);
    Route::delete('/provider/portfolio/{id}', [\App\Http\Controllers\Api\PortfolioController::class, 'destroy']);

    // routes/api.php
    Route::get('/provider/reservations', [ReservationController::class, 'index']);
    Route::patch('/reservations/{id}/status', [ReservationController::class, 'updateStatus']);
    Route::get('/client/my-reservations', [ReservationController::class, 'getMyReservations']);

    Route::get('/reservations/{id}', [ReservationController::class, 'show']);
    Route::post('/reservations/{id}/location', [ReservationController::class, 'updateLocation']);
    Route::get('/client-reservations/{providerId}', [ReservationController::class, 'getClientReservationsForProvider']);

    Route::post('/reservations/{provider}', [ReservationController::class, 'store']);

    Route::get('/reservations/provider/{provider}', [ReservationController::class, 'getForProvider']);
    Route::get('/reservations/{reservation}/messages', [ReservationController::class, 'getMessages']);
    Route::post('/reservations/{reservation}/messages', [ReservationController::class, 'sendMessage']);

    Route::post('/devices/register', [DeviceTokenController::class, 'register']);
    Route::post('/devices/unregister', [DeviceTokenController::class, 'unregister']);
    Route::post('/notifications/test', [DeviceTokenController::class, 'test']); // envoi de test


    Route::post('/favorite/{provider}', [FavoriteController::class, 'toggle']);
    Route::get('/favorites', [FavoriteController::class, 'list']);

    // Gestion du Planning (Disponibilités)
    Route::get('/availabilities', [\App\Http\Controllers\AvailabilityController::class, 'index']);
    Route::post('/availabilities', [\App\Http\Controllers\AvailabilityController::class, 'update']);

    // SOS Urgence
    Route::post('/sos', [\App\Http\Controllers\SOSController::class, 'store']);
    Route::post('/sos/accept', [\App\Http\Controllers\SOSController::class, 'accept']);

    // Reports / Litiges
    Route::post('/reports', [\App\Http\Controllers\Api\ReportController::class, 'store']);


    // Wallet / Portefeuille
    Route::get('/wallet', [\App\Http\Controllers\WalletController::class, 'index']);
    Route::post('/wallet/recharge', [\App\Http\Controllers\WalletController::class, 'recharge']);

    // Admin Tracking
    Route::get('/admin/reservations/ongoing', [ReservationController::class, 'getOngoingReservations']);
    
    // Admin - Provider Validation Management
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/dashboard/stats', [\App\Http\Controllers\AdminController::class, 'getDashboardStats']);
        Route::get('/providers/pending', [\App\Http\Controllers\AdminController::class, 'getPendingProviders']);
        Route::get('/providers/validated', [\App\Http\Controllers\AdminController::class, 'getValidatedProviders']);
        Route::post('/providers/{id}/validate', [\App\Http\Controllers\AdminController::class, 'validateProvider']);
        Route::delete('/providers/{id}/reject', [\App\Http\Controllers\AdminController::class, 'rejectProvider']);
        Route::get('/users', [\App\Http\Controllers\AdminController::class, 'getAllUsers']);
        Route::put('/users/{id}', [\App\Http\Controllers\AdminController::class, 'updateUser']);
        Route::delete('/users/{id}', [\App\Http\Controllers\AdminController::class, 'deleteUser']);
        
        // 💰 Gestion des Portefeuilles & Commissions
        Route::get('/wallet/overview', [\App\Http\Controllers\AdminController::class, 'getWalletOverview']);
        Route::get('/transactions', [\App\Http\Controllers\AdminController::class, 'getAllTransactions']);
        Route::get('/wallet/provider/{id}', [\App\Http\Controllers\AdminController::class, 'getProviderWallet']);
        Route::post('/wallet/adjust/{userId}', [\App\Http\Controllers\AdminController::class, 'adjustBalance']);
        Route::get('/commissions/stats', [\App\Http\Controllers\AdminController::class, 'getCommissionStats']);
        
        // 💸 Collecte des Commissions par l'Admin
        Route::post('/commissions/collect', [\App\Http\Controllers\AdminController::class, 'collectCommissions']);
        Route::get('/commissions/history', [\App\Http\Controllers\AdminController::class, 'getCollectionHistory']);
    });
});     // Profil prestataire
Route::get('/professions/populaires', [ProviderController::class, 'popularProfessions']);
Route::get('/professions/{profession}/prestataires', [ProviderController::class, 'prestatairesByProfession']);
Route::get('/professions', [ProfessionController::class, 'index']);

Route::apiResource('users', UserController::class);