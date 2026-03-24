<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AcceptedChallengesLikes extends Model
{
    use HasFactory;

    protected $table = 'accepted_challenges_likes';

    protected $fillable = ['user_id', 'accepted_challenge_id', 'type'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function acceptedChallenge()
    {
        return $this->belongsTo(AcceptedChallenge::class, 'accepted_challenge_id');
    }
}
