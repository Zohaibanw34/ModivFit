<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notifications;
use Illuminate\Http\Request;

class NotificationsController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = Notifications::query()->where('user_id', $user->id)->orderByDesc('id');
        if ($request->query('unread') === '1') {
            $query->whereNull('read_at');
        }

        $items = $query->limit(50)->get()->map(fn (Notifications $n) => $this->payload($n))->values();

        return response()->json([
            'success' => true,
            'message' => 'Notifications fetched',
            'data' => [
                'notifications' => $items,
                'items' => $items,
            ],
        ]);
    }

    public function create(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'body' => ['nullable', 'string', 'max:2000'],
            'description' => ['nullable', 'string', 'max:2000'],
        ]);

        $n = Notifications::create([
            'user_id' => $user->id,
            'title' => $data['title'] ?? null,
            'description' => $data['body'] ?? $data['description'] ?? null,
        ]);

        return response()->json([
            'message' => 'Notification created',
            'data' => $this->payload($n),
        ]);
    }

    public function unreadCount(Request $request)
    {
        $user = $request->user();
        $count = Notifications::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'message' => 'Unread count fetched',
            'data' => [
                'count' => $count,
                'unread_count' => $count,
            ],
        ]);
    }

    public function action(Request $request, string $id)
    {
        $user = $request->user();
        $action = strtolower((string) $request->input('action'));

        $n = Notifications::query()->where('user_id', $user->id)->where('id', $id)->firstOrFail();

        if ($action === 'read') {
            $n->read_at = now();
            $n->save();
        }

        return response()->json([
            'message' => 'Notification updated',
            'data' => $this->payload($n),
        ]);
    }

    public function read(Request $request, string $id)
    {
        // Compatibility with ApiConfig.notificationReadUrl(id)
        $request->merge(['action' => 'read']);
        return $this->action($request, $id);
    }

    public function markAllRead(Request $request)
    {
        $user = $request->user();
        Notifications::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'message' => 'All notifications marked as read',
        ]);
    }

    public function readAll(Request $request)
    {
        return $this->markAllRead($request);
    }

    private function payload(Notifications $n): array
    {
        return [
            'id' => (string) $n->id,
            'title' => $n->title,
            'body' => $n->description,
            'description' => $n->description,
            'type' => $n->type,
            'action_type' => $n->action_type,
            'action_id' => $n->action_id,
            'read_at' => optional($n->read_at)->toIso8601String(),
            'created_at' => optional($n->created_at)->toIso8601String(),
        ];
    }
}

