<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubComments extends Model
{
    use HasFactory;

    protected $table = 'sub_comments';

    protected $fillable = ['user_id', 'comment_id', 'description'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function comment()
    {
        return $this->belongsTo(Comments::class);
    }
}
