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
        Schema::create('provider_badges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('badge_type'); // top_rated, responsive, verified, expert, etc.
            $table->string('badge_label');
            $table->string('badge_icon')->nullable();
            $table->string('badge_color')->default('#4F46E5');
            $table->text('description')->nullable();
            $table->timestamp('earned_at');
            $table->timestamps();

            $table->unique(['user_id', 'badge_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('provider_badges');
    }
};
