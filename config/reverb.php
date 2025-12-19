<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Reverb Server
    |--------------------------------------------------------------------------
    |
    | This option controls the default server used by Reverb to handle
    | incoming websocket connections. This should correspond to one of the
    | servers configured in the "servers" configuration array below.
    |
    */

    'default' => env('REVERB_SERVER', 'reverb'),

    /*
    |--------------------------------------------------------------------------
    | Reverb Servers
    |--------------------------------------------------------------------------
    |
    | Here you may define all of the Reverb servers for your application.
    | You'll typically only need to configure the "reverb" server but you
    | are free to add additional servers as needed by your application.
    |
    */

    'servers' => [

        'reverb' => [
            'host' => env('REVERB_SERVER_HOST', '0.0.0.0'),
            'port' => env('REVERB_SERVER_PORT', 8080),
            'hostname' => env('REVERB_HOST'),
            'options' => [
                'tls' => [],
            ],
            'scaling' => [
                'enabled' => env('REVERB_SCALING_ENABLED', false),
                'channel' => env('REVERB_SCALING_CHANNEL', 'reverb'),
            ],
            'pulse_ingest_interval' => env('REVERB_PULSE_INGEST_INTERVAL', 15),
            'telescope_ingest_interval' => env('REVERB_TELESCOPE_INGEST_INTERVAL', 15),
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Reverb Applications
    |--------------------------------------------------------------------------
    |
    | Here you may define all of the applications that will be managed by
    | the Reverb server. Each application has its own unique credentials
    | which can be used to connect to the Reverb server from your app.
    |
    */

    'apps' => [

        'apps' => [
            [
                'app_id' => env('REVERB_APP_ID', 'inginia'),
                'app_key' => env('REVERB_APP_KEY', 'inginia-key'),
                'app_secret' => env('REVERB_APP_SECRET', 'inginia-secret'),
                'capacity' => null,
                'allowed_origins' => ['*'],
            ],
        ],

    ],

];
