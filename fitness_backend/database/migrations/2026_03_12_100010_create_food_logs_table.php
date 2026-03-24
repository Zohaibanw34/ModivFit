<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title')->nullable();
            $table->string('type')->nullable();
            $table->double('calories', 8, 2)->nullable()->default(0);
            $table->double('protein', 8, 2)->nullable()->default(0);
            $table->double('carbs', 8, 2)->nullable()->default(0);
            $table->double('fats', 8, 2)->nullable()->default(0);
            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('food_logs');
    }
};
