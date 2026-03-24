<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubCommentsLikes extends Model
{
    use HasFactory;

    protected $table = 'sub_comments_likes';

    protected $fillable = ['user_id', 'sub_comment_id', 'type'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function subComment()
    {
        return $this->belongsTo(SubComments::class, 'sub_comment_id');
    }
}
