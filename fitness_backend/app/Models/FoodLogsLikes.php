<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FoodLogsLikes extends Model
{
    use HasFactory;

    protected $table = 'food_logs_likes';

    protected $fillable = ['user_id', 'food_log_id', 'type'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function foodLog()
    {
        return $this->belongsTo(FoodLogs::class, 'food_log_id');
    }
}
