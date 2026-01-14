<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('avis', function (Blueprint $table) {
            // Critères de notation détaillés (1-5 pour chaque)
            $table->tinyInteger('ponctualite')->nullable()->comment('Note ponctualité 1-5');
            $table->tinyInteger('qualite')->nullable()->comment('Note qualité du travail 1-5');
            $table->tinyInteger('prix')->nullable()->comment('Note rapport qualité/prix 1-5');
            $table->tinyInteger('communication')->nullable()->comment('Note communication 1-5');
            
            // Photos dans les avis (JSON array de chemins)
            $table->json('photos')->nullable()->comment('Tableau de chemins vers les photos');
            
            // Réponse du prestataire
            $table->text('reponse_prestataire')->nullable();
            $table->timestamp('reponse_at')->nullable();
            
            // Métadonnées
            $table->boolean('verified')->default(false)->comment('Avis vérifié (mission complétée)');
            $table->boolean('helpful_count')->default(0)->comment('Nombre de "utile"');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('avis', function (Blueprint $table) {
            $table->dropColumn([
                'ponctualite',
                'qualite', 
                'prix',
                'communication',
                'photos',
                'reponse_prestataire',
                'reponse_at',
                'verified',
                'helpful_count'
            ]);
        });
    }
};
