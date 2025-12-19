<?php

namespace App\Providers;


use Illuminate\Support\ServiceProvider;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Contract\Messaging;


class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        // $this->app->singleton(FcmService::class, function ($app) {
        //     $factory = (new Factory)
        //         ->withServiceAccount(storage_path('firebase/serviceAccount.json'));
        //     $messaging = $factory->createMessaging();
        //     return new FcmService($messaging);
        // });
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        //
    }
}
