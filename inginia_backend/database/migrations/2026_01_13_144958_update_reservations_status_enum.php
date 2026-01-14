<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // First drop the old check constraint
        DB::statement('ALTER TABLE reservations DROP CONSTRAINT IF EXISTS reservations_status_check');
        
        // Add the new check constraint with all statuses
        DB::statement("ALTER TABLE reservations ADD CONSTRAINT reservations_status_check CHECK (status::text IN ('pending', 'accepted', 'declined', 'completed', 'cancelled', 'in_progress'))");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE reservations DROP CONSTRAINT IF EXISTS reservations_status_check');
        DB::statement("ALTER TABLE reservations ADD CONSTRAINT reservations_status_check CHECK (status::text IN ('pending', 'accepted', 'declined', 'completed'))");
    }
};
