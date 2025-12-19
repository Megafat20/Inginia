<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Broadcaster
    |--------------------------------------------------------------------------
    |
    | This option controls the default broadcaster that will be used by the
    | framework when an event needs to be broadcast. You may set this to
    | any of the connections defined in the "connections" array below.
    |
    | Supported: "pusher", "ably", "redis", "log", "null"
    |
    */

    'default' => env('BROADCAST_DRIVER', 'null'),

    /*
    |--------------------------------------------------------------------------
    | Broadcast Connections
    |--------------------------------------------------------------------------
    |
    | Here you may define all of the broadcast connections that will be used
    | to broadcast events to other systems or over websockets. Samples of
    | each available type of connection are provided inside this array.
    |
    */

    'connections' => [

        'pusher' => [
            'driver' => 'pusher',
            // On ignore PUSHER_APP_KEY car il contient souvent une valeur bidon (abcdef)
            // On force inginia-key si REVERB_APP_KEY est absent
            'key' => env('REVERB_APP_KEY', 'inginia-key'),
            'secret' => env('REVERB_APP_SECRET', 'inginia-secret'),
            'app_id' => env('REVERB_APP_ID', 'inginia'),
            'options' => [
                'cluster' => env('PUSHER_APP_CLUSTER'),
                // Forcer 127.0.0.1 pour éviter résolution IPv6 problématique sur Windows
                'host' => '127.0.0.1',
                'port' => env('REVERB_PORT', env('PUSHER_PORT', 8080)),
                'scheme' => 'http',
                'encrypted' => false,
                'useTLS' => false,
            ],
            'client_options' => [
                // Guzzle client options: verify => false (pour dev local Reverb)
                'verify' => false,
            ],
        ],


        'ably' => [
            'driver' => 'ably',
            'key' => env('ABLY_KEY'),
        ],

        'redis' => [
            'driver' => 'redis',
            'connection' => 'default',
        ],

        'log' => [
            'driver' => 'log',
        ],

        'null' => [
            'driver' => 'null',
        ],

        'reverb' => [
            'driver' => 'reverb',
            'key' => env('REVERB_APP_KEY'),
            'secret' => env('REVERB_APP_SECRET'),
            'app_id' => env('REVERB_APP_ID'),
            'options' => [
                'host' => env('REVERB_HOST'),
                'port' => env('REVERB_PORT', 443),
                'scheme' => env('REVERB_SCHEME', 'https'),
                'useTLS' => env('REVERB_SCHEME', 'https') === 'https',
            ],
            'client_options' => [
                // Guzzle client options: service non requis en local généralement
                'verify' => false,
            ],
        ],

    ],

];
