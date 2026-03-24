<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Challenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'time',
        'media',
        'category',
        'level',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function comments()
    {
        return $this->hasMany(Comments::class);
    }

    public function likes()
    {
        return $this->hasMany(ChallengeLikes::class);
    }

    public function acceptedChallenges()
    {
        return $this->hasMany(AcceptedChallenge::class);
    }
}
