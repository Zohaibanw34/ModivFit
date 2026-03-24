<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Chats extends Model
{
    use HasFactory;

    protected $table = 'chats';

    protected $fillable = ['user_id', 'challenge_id', 'is_admin'];

    protected function casts(): array
    {
        return [
            'is_admin' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function challenge()
    {
        return $this->belongsTo(Challenge::class);
    }

    public function messages()
    {
        return $this->hasMany(ChatMessages::class, 'chat_id');
    }
}
