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
Route::get('/providers', [UserController::class, 'getProvidersAndServices']);
Route::middleware('auth:api')->group(function () {

    
    

    Route::post('/prestataires/recommandes', [HomeController::class, 'recommanderPrestataires']);


    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::put('/me', [UserController::class, 'update']);
    Route::put('/me/password', [UserController::class, 'updatePassword']);

    Route::get('/avis/{prestataire_id}', [AvisController::class, 'show']);
    Route::post('/avis/{prestataire_id}', [AvisController::class, 'store']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/users/fcm-token', [UserController::class, 'updateFcmToken']);

    Route::get('/provider/profile', [ProviderController::class, 'profile']);
    Route::get('/provider/stats', [ProviderController::class, 'getProviderStat']);
    Route::post('/provider/services', [ProviderController::class, 'addService']);
    Route::get('/provider/{id}/services', [ProviderController::class, 'getServicesByProviderId']);

    Route::get('/provider/{id}/dashboard', [ProviderController::class, 'getFullDashboard']);
    Route::get('/provider/myprofessions', [ProviderController::class, 'myProfessions']);
    // routes/api.php
    Route::get('/provider/reservations', [ReservationController::class, 'index']);
    Route::patch('/provider/reservations/{id}', [ReservationController::class, 'updateStatus']);
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
});     // Profil prestataire
Route::get('/professions/populaires', [ProviderController::class, 'popularProfessions']);
Route::get('/professions/{profession}/prestataires', [ProviderController::class, 'prestatairesByProfession']);
Route::get('/professions', [ProfessionController::class, 'index']);

Route::apiResource('users', UserController::class);