<?php

namespace App\Services;

use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\WebPushConfig;

class FcmService
{
    protected $messaging;

    public function __construct(Messaging $messaging)
    {
        $this->messaging = $messaging;
    }

    /**
     * Envoyer une notification à un token FCM
     *
     * @param string $token
     * @param string $title
     * @param string $body
     * @param array $data
     */
    public function sendToToken(string $token, string $title, string $body, array $data = [])
    {
        $message = CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData($data)
            ->withWebPushConfig(WebPushConfig::fromArray([
                'notification' => [
                    'icon' => '/icons/icon-192x192.png',
                ],
            ]));

        $this->messaging->send($message->withChangedTarget('token', $token));
    }

    public function sendNotification(array $tokens, string $title, string $body)
    {
        foreach ($tokens as $token) {
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification(Notification::create($title, $body));

            $this->messaging->send($message);
        }
    }
}
