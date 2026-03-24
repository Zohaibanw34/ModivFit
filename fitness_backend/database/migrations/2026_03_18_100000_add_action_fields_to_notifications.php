<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('type', 64)->nullable()->after('description');
            $table->string('action_type', 64)->nullable()->after('type');
            $table->string('action_id', 128)->nullable()->after('action_type');
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropColumn(['type', 'action_type', 'action_id']);
        });
    }
};
