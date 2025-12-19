<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "Current Broadcast Driver: [" . config('broadcasting.default') . "]\n";
echo "Reverb Connection Configured: " . (is_array(config('broadcasting.connections.reverb')) ? 'YES' : 'NO') . "\n";
