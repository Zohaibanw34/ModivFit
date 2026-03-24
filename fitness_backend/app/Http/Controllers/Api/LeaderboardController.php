<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    public function index(Request $request)
    {
        $gender = $request->query('gender'); // male|female or null

        $query = User::query()
            ->select(['id', 'name', 'gender', 'media', 'points'])
            ->orderByDesc('points')
            ->orderBy('id');

        if (is_string($gender) && $gender !== '') {
            $normalized = strtolower(trim($gender));
            $query->where('gender', $normalized);
        }

        $users = $query->limit(100)->get();

        $items = [];
        $rank = 1;
        foreach ($users as $user) {
            $items[] = [
                'id' => (string) $user->id,
                'name' => $user->name,
                'gender' => $user->gender,
                'points' => $user->points ?? 0,
                'rank' => $rank++,
                'avatar_url' => $user->media
                    ? (\str_starts_with((string) $user->media, 'http') ? $user->media : \Storage::disk('public')->url($user->media))
                    : null,
            ];
        }

        return response()->json([
            'success' => true,
            'message' => 'Leaderboard fetched',
            'data' => [
                'items' => $items,
            ],
        ]);
    }
}

