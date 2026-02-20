<?php

namespace App\Services;

use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
use Illuminate\Support\Facades\Log;

class FcmService
{
    protected $messaging;

    public function __construct(Messaging $messaging)
    {
        $this->messaging = $messaging;
    }

    /**
     * Envoyer une notification à un token FCM avec configuration avancée
     */
    public function sendToToken(string $token, string $title, string $body, array $data = [], array $options = [])
    {
        try {
            $notification = Notification::create($title, $body);
            
            if (isset($options['image'])) {
                $notification = $notification->withImageUrl($options['image']);
            }

            $message = CloudMessage::new()
                ->withNotification($notification)
                ->withData(array_merge($data, [
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'timestamp' => now()->toIso8601String(),
                ]));

            // Configuration Android
            $message = $message->withAndroidConfig(
                AndroidConfig::fromArray([
                    'priority' => $options['priority'] ?? 'high',
                    'notification' => [
                        'sound' => $options['sound'] ?? 'default',
                        'color' => $options['color'] ?? '#4F46E5',
                        'channel_id' => $options['channel_id'] ?? 'default',
                        'default_sound' => true,
                        'default_vibrate_timings' => true,
                    ],
                ])
            );

            // Configuration iOS
            $message = $message->withApnsConfig(
                ApnsConfig::fromArray([
                    'headers' => [
                        'apns-priority' => '10',
                    ],
                    'payload' => [
                        'aps' => [
                            'alert' => [
                                'title' => $title,
                                'body' => $body,
                            ],
                            'sound' => $options['sound'] ?? 'default',
                            'badge' => $options['badge'] ?? 1,
                            'mutable-content' => 1,
                        ],
                    ],
                ])
            );

            $response = $this->messaging->send($message->withChangedTarget('token', $token));
            
            Log::info('FCM notification sent successfully', [
                'token' => substr($token, 0, 20) . '...',
                'title' => $title,
                'response' => $response,
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('FCM notification failed', [
                'error' => $e->getMessage(),
                'token' => substr($token, 0, 20) . '...',
            ]);
            return false;
        }
    }

    /**
     * Envoyer une notification à plusieurs tokens
     */
    public function sendToMultipleTokens(array $tokens, string $title, string $body, array $data = [], array $options = [])
    {
        $successCount = 0;
        foreach ($tokens as $token) {
            if ($this->sendToToken($token, $title, $body, $data, $options)) {
                $successCount++;
            }
        }
        return $successCount;
    }

    /**
     * Notification pour nouvelle réservation
     */
    public function sendNewReservationNotification(string $token, array $reservationData)
    {
        return $this->sendToToken(
            $token,
            '🔔 Nouvelle Demande !',
            "Nouvelle demande de {$reservationData['client_name']} pour {$reservationData['service']}",
            [
                'type' => 'new_reservation',
                'reservation_id' => (string) $reservationData['id'],
                'screen' => 'reservation_details',
            ],
            [
                'sound' => 'notification_sound.mp3',
                'color' => '#10B981',
                'channel_id' => 'reservations',
                'badge' => 1,
            ]
        );
    }

    /**
     * Notification pour changement de statut
     */
    public function sendStatusChangeNotification(string $token, string $status, array $reservationData)
    {
        $messages = [
            'accepted' => '✅ Demande acceptée !',
            'declined' => '❌ Demande refusée',
            'completed' => '🎉 Mission terminée !',
            'cancelled' => '⚠️ Mission annulée',
        ];

        $bodies = [
            'accepted' => "Votre demande a été acceptée par {$reservationData['provider_name']}",
            'declined' => "Votre demande a été refusée par {$reservationData['provider_name']}",
            'completed' => "La mission avec {$reservationData['provider_name']} est terminée",
            'cancelled' => "La mission a été annulée",
        ];

        return $this->sendToToken(
            $token,
            $messages[$status] ?? 'Mise à jour',
            $bodies[$status] ?? 'Statut de votre réservation mis à jour',
            [
                'type' => 'status_change',
                'status' => $status,
                'reservation_id' => (string) $reservationData['id'],
                'screen' => 'reservation_details',
            ],
            [
                'sound' => 'default',
                'color' => $status === 'accepted' ? '#10B981' : ($status === 'declined' ? '#EF4444' : '#F59E0B'),
                'channel_id' => 'status_updates',
            ]
        );
    }

    /**
     * Notification pour nouveau message
     */
    public function sendNewMessageNotification(string $token, array $messageData)
    {
        return $this->sendToToken(
            $token,
            "💬 {$messageData['sender_name']}",
            $messageData['message_preview'],
            [
                'type' => 'new_message',
                'reservation_id' => (string) $messageData['reservation_id'],
                'sender_id' => (string) $messageData['sender_id'],
                'screen' => 'chat',
            ],
            [
                'sound' => 'default',
                'color' => '#3B82F6',
                'channel_id' => 'messages',
            ]
        );
    }

    /**
     * Notification d'urgence (SOS)
     */
    public function sendUrgentNotification(string $token, array $urgentData)
    {
        return $this->sendToToken(
            $token,
            '🚨 URGENCE !',
            "Demande urgente de {$urgentData['client_name']} - {$urgentData['problem_type']}",
            [
                'type' => 'urgent_request',
                'request_id' => (string) $urgentData['id'],
                'client_name' => $urgentData['client_name'],
                'problem_type' => $urgentData['problem_type'],
                'screen' => 'urgent_request',
            ],
            [
                'priority' => 'high',
                'sound' => 'default',
                'color' => '#DC2626',
                'channel_id' => 'urgent',
                'badge' => 1,
            ]
        );
    }

    /**
     * Notification de rappel
     */
    public function sendReminderNotification(string $token, array $reminderData)
    {
        return $this->sendToToken(
            $token,
            '⏰ Rappel',
            $reminderData['message'],
            [
                'type' => 'reminder',
                'reservation_id' => (string) $reminderData['reservation_id'],
                'screen' => 'reservation_details',
            ],
            [
                'sound' => 'default',
                'color' => '#F59E0B',
                'channel_id' => 'reminders',
            ]
        );
    }

    /**
     * Notification de proximité (prestataire proche)
     */
    public function sendProximityNotification(string $token, array $providerData)
    {
        return $this->sendToToken(
            $token,
            '📍 Prestataire en approche',
            "{$providerData['provider_name']} arrive dans {$providerData['eta']} minutes",
            [
                'type' => 'proximity',
                'reservation_id' => (string) $providerData['reservation_id'],
                'eta' => (string) $providerData['eta'],
                'screen' => 'tracking',
            ],
            [
                'sound' => 'default',
                'color' => '#8B5CF6',
                'channel_id' => 'tracking',
            ]
        );
    }
}
