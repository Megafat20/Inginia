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
        Schema::table('users', function (Blueprint $table) {
            $table->integer('jobs_completed')->default(0);
            $table->integer('response_time_minutes')->nullable(); // Temps moyen de réponse en minutes
            $table->timestamp('verified_at')->nullable(); // KYC Verification date
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['jobs_completed', 'response_time_minutes', 'verified_at']);
        });
    }
};
