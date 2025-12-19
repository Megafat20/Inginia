<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "--- Reverb Debug ---\n";
echo "REVERB_APP_ID: " . env('REVERB_APP_ID', 'N/A') . "\n";
echo "REVERB_SERVER_HOST: " . env('REVERB_SERVER_HOST', 'N/A') . "\n";
echo "REVERB_SCALING_ENABLED: " . (env('REVERB_SCALING_ENABLED') ? 'TRUE' : 'FALSE') . "\n";
echo "CACHE_STORE: " . env('CACHE_STORE', 'N/A') . "\n";
echo "DB_CONNECTION: " . env('DB_CONNECTION', 'N/A') . "\n";

$config = config('broadcasting.connections.pusher');
echo "\n--- Config Broadcasting (Pusher Driver) ---\n";
echo "Host: " . $config['options']['host'] . "\n";
echo "Port: " . $config['options']['port'] . "\n";
echo "App ID: " . $config['app_id'] . "\n";
