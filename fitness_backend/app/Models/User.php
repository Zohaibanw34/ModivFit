<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'height',
        'weight',
        'fitness_level',
        'goal',
        'points',
        'date_of_birth',
        'gender',
        'fcm_token',
        'media',
        'user_name',
        'country',
        'login_type',
        'bio',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'date_of_birth' => 'date',
            'password' => 'hashed',
            'points' => 'float',
        ];
    }

    public function challenges()
    {
        return $this->hasMany(Challenge::class);
    }

    public function comments()
    {
        return $this->hasMany(Comments::class);
    }

    public function challengeLikes()
    {
        return $this->hasMany(ChallengeLikes::class);
    }

    public function verifications()
    {
        return $this->hasMany(Verification::class);
    }

    public function followers()
    {
        return $this->hasMany(Followers::class, 'followed_id');
    }

    public function followings()
    {
        return $this->hasMany(Followers::class, 'follower_id');
    }

    public function reels()
    {
        return $this->hasMany(Reel::class);
    }
}
