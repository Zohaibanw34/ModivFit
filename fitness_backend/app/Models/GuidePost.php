<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GuidePost extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'topic',
        'title',
        'body',
        'likes_count',
        'replies_count',
    ];

    protected $casts = [
        'likes_count' => 'integer',
        'replies_count' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function replies(): HasMany
    {
        return $this->hasMany(GuidePostReply::class);
    }
}

