<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accepted_challenges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('challenge_id')->constrained()->cascadeOnDelete();
            $table->string('level')->nullable();
            $table->text('description')->nullable();
            $table->double('time', 8, 2)->nullable();
            $table->integer('reports')->default(0);
            $table->string('media')->nullable();
            $table->string('status', 32)->nullable()->default('active');
            $table->dateTime('media_upload_time')->nullable();
            $table->string('type', 32)->nullable()->default('public');
            $table->boolean('points_awarded')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('accepted_challenges');
    }
};
