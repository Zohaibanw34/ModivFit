<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('reel_reactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('reel_id');
            $table->string('type', 20); // like, dislike, favorite
            $table->timestamps();

            $table->unique(['user_id', 'reel_id', 'type']);
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('reel_id')->references('id')->on('reels')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reel_reactions');
    }
};
