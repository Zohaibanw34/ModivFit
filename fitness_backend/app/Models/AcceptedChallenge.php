<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AcceptedChallenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'challenge_id',
        'level',
        'description',
        'time',
        'reports',
        'media',
        'status',
        'progress',
        'media_upload_time',
        'type',
        'points_awarded',
    ];

    protected $casts = [
        'progress' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function challenge()
    {
        return $this->belongsTo(Challenge::class);
    }

    public function likes()
    {
        return $this->hasMany(AcceptedChallengesLikes::class, 'accepted_challenge_id');
    }
}
