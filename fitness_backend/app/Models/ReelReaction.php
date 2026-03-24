<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReelReaction extends Model
{
    protected $fillable = ['user_id', 'reel_id', 'type'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function reel(): BelongsTo
    {
        return $this->belongsTo(Reel::class);
    }
}
