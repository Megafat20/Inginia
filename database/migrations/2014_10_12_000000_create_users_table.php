<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->enum('role', ['client', 'prestataire', 'service','admin'])->default('client');
            $table->boolean('is_verified')->default(false); 
            $table->string('phone')->nullable();
            $table->string('profession')->nullable();
            $table->string('service')->nullable();
            $table->boolean('kyc_verified')->default(false);
            $table->string('photo')->nullable();
            $table->decimal('rating', 3, 2)->default(0);
            $table->string('location')->nullable();
            $table->string('adresse')->nullable();
            $table->float('min_price')->nullable();
            $table->string('slogan')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('users');
    }
};
