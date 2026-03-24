<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChatMessages extends Model
{
    use HasFactory;

    protected $table = 'chat_messages';

    protected $fillable = ['sender_id', 'challenge_id', 'chat_id', 'message', 'media', 'message_type'];

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function challenge()
    {
        return $this->belongsTo(Challenge::class);
    }

    public function chat()
    {
        return $this->belongsTo(Chats::class, 'chat_id');
    }
}
