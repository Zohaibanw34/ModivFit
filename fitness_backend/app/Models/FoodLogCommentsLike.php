<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FoodLogCommentsLike extends Model
{
    use HasFactory;

    protected $table = 'food_log_comments_likes';

    protected $fillable = ['user_id', 'food_log_comment_id', 'type'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function foodLogComment()
    {
        return $this->belongsTo(FoodLogComments::class, 'food_log_comment_id');
    }
}
