<?php

namespace App\Services;

use App\Models\User;
use App\Models\Avis;
use App\Models\Reservation;
use Illuminate\Support\Facades\DB;

class BadgeService
{
    /**
     * Vérifier et attribuer les badges à un prestataire
     */
    public function updateProviderBadges(int $providerId): array
    {
        $provider = User::findOrFail($providerId);
        $earnedBadges = [];

        // Badge "Top Rated" - Note moyenne >= 4.5 avec au moins 10 avis
        if ($this->qualifiesForTopRated($provider)) {
            $earnedBadges[] = $this->awardBadge($provider, 'top_rated', '⭐ Top Rated', '#FFD700', 'Note moyenne supérieure à 4.5');
        }

        // Badge "Réactif" - Temps de réponse moyen < 2h
        if ($this->qualifiesForResponsive($provider)) {
            $earnedBadges[] = $this->awardBadge($provider, 'responsive', '⚡ Réactif', '#3B82F6', 'Répond en moins de 2h');
        }

        // Badge "Vérifié" - Profil complet + au moins 5 missions complétées
        if ($this->qualifiesForVerified($provider)) {
            $earnedBadges[] = $this->awardBadge($provider, 'verified', '✓ Vérifié', '#10B981', 'Profil vérifié et expérimenté');
        }

        // Badge "Expert" - Plus de 50 missions complétées
        if ($this->qualifiesForExpert($provider)) {
            $earnedBadges[] = $this->awardBadge($provider, 'expert', '🏆 Expert', '#8B5CF6', 'Plus de 50 missions réussies');
        }

        // Badge "Ponctuel" - Note ponctualité moyenne >= 4.5
        if ($this->qualifiesForPunctual($provider)) {
            $earnedBadges[] = $this->awardBadge($provider, 'punctual', '⏰ Ponctuel', '#F59E0B', 'Toujours à l\'heure');
        }

        return array_filter($earnedBadges);
    }

    private function qualifiesForTopRated(User $provider): bool
    {
        $avgRating = Avis::where('prestataire_id', $provider->id)->avg('note');
        $reviewCount = Avis::where('prestataire_id', $provider->id)->count();
        
        return $avgRating >= 4.5 && $reviewCount >= 10;
    }

    private function qualifiesForResponsive(User $provider): bool
    {
        // Calculer le temps de réponse moyen (acceptation de réservation)
        $avgResponseTime = Reservation::where('provider_id', $provider->id)
            ->where('status', '!=', 'pending')
            ->selectRaw('AVG(TIMESTAMPDIFF(HOUR, created_at, updated_at)) as avg_hours')
            ->value('avg_hours');

        return $avgResponseTime !== null && $avgResponseTime < 2;
    }

    private function qualifiesForVerified(User $provider): bool
    {
        $completedMissions = Reservation::where('provider_id', $provider->id)
            ->where('status', 'completed')
            ->count();

        $hasCompleteProfile = !empty($provider->phone) && 
                             !empty($provider->adresse) && 
                             !empty($provider->photo);

       return $completedMissions >= 5 && $hasCompleteProfile;
    }

    private function qualifiesForExpert(User $provider): bool
    {
        $completedMissions = Reservation::where('provider_id', $provider->id)
            ->where('status', 'completed')
            ->count();

        return $completedMissions >= 50;
    }

    private function qualifiesForPunctual(User $provider): bool
    {
        $avgPonctualite = Avis::where('prestataire_id', $provider->id)
            ->whereNotNull('ponctualite')
            ->avg('ponctualite');

        return $avgPonctualite >= 4.5;
    }

    private function awardBadge(User $provider, string $type, string $label, string $color, string $description): ?array
    {
        $badge = DB::table('provider_badges')->updateOrInsert(
            ['user_id' => $provider->id, 'badge_type' => $type],
            [
                'badge_label' => $label,
                'badge_color' => $color,
                'description' => $description,
                'earned_at' => now(),
                'updated_at' => now(),
                'created_at' => DB::raw('COALESCE(created_at, NOW())'),
            ]
        );

        return $badge ? [
            'type' => $type,
            'label' => $label,
            'color' => $color,
            'description' => $description
        ] : null;
    }

    /**
     * Récupérer les badges d'un prestataire
     */
    public function getProviderBadges(int $providerId): array
    {
        return DB::table('provider_badges')
            ->where('user_id', $providerId)
            ->orderBy('earned_at', 'desc')
            ->get()
            ->map(fn($badge) => [
                'type' => $badge->badge_type,
                'label' => $badge->badge_label,
                'color' => $badge->badge_color,
                'description' => $badge->description,
                'earned_at' => $badge->earned_at,
            ])
            ->toArray();
    }
}
