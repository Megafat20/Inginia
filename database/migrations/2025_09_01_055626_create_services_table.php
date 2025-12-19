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
        Schema::create('services', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('provider_id'); // le prestataire ou l'agence
            $table->unsignedBigInteger('profession_id')->nullable(); // rattacher le service à une profession
            $table->string('title');        // ex: "Réparation ordinateur"
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2)->nullable();
            $table->timestamps();
        
            $table->foreign('provider_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('profession_id')->references('id')->on('professions')->onDelete('set null');
        });
        
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('services');
    }
};
