<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Reel extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'media_path',
        'caption',
        'hashtags',
        'visibility',
        'like_count',
        'view_count',
    ];

    protected $casts = [
        'hashtags' => 'array',
        'like_count' => 'integer',
        'view_count' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(ReelComment::class);
    }
}

