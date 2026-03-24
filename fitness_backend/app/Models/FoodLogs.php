<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FoodLogs extends Model
{
    use HasFactory;

    protected $table = 'food_logs';

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'calories',
        'protein',
        'carbs',
        'fats',
        'type',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function likes()
    {
        return $this->hasMany(FoodLogsLikes::class, 'food_log_id');
    }

    public function comments()
    {
        return $this->hasMany(FoodLogComments::class, 'food_log_id');
    }
}
