<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('reels', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('media_path');
            $table->text('caption')->nullable();
            $table->json('hashtags')->nullable();
            $table->string('visibility', 20)->default('public'); // public / friends / private
            $table->unsignedBigInteger('like_count')->default(0);
            $table->unsignedBigInteger('view_count')->default(0);
            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reels');
    }
};

