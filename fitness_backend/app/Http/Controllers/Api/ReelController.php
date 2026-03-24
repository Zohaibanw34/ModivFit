<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reel;
use App\Models\ReelComment;
use App\Models\ReelReaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReelController extends Controller
{
    public function index(Request $request)
    {
        $query = Reel::with('user')->withCount('comments')->latest();

        if ($request->has('user_id')) {
            $query->where('user_id', $request->integer('user_id'));
        }

        $search = $request->query('search');
        if (is_string($search) && trim($search) !== '') {
            $term = '%'.trim($search).'%';
            $query->where(function ($q) use ($term) {
                $q->where('caption', 'like', $term)
                    ->orWhereHas('user', function ($u) use ($term) {
                        $u->where('name', 'like', $term)
                            ->orWhere('user_name', 'like', $term);
                    });
            });
        }

        $viewer = $request->user();
        if ($viewer) {
            $notInterestedReelIds = ReelReaction::where('user_id', $viewer->id)
                ->where('type', 'not_interested')
                ->pluck('reel_id');
            if ($notInterestedReelIds->isNotEmpty()) {
                $query->whereNotIn('id', $notInterestedReelIds);
            }
        }

        $reels = $query->paginate(20);
        $collection = $reels->getCollection();
        $viewerReactions = $this->viewerReactionsMap($request->user(), $collection->pluck('id')->all());

        return response()->json([
            'success' => true,
            'data' => [
                'items' => $collection->map(
                    fn (Reel $reel) => $this->payload($reel, $viewerReactions[$reel->id] ?? null)
                ),
                'pagination' => [
                    'current_page' => $reels->currentPage(),
                    'last_page' => $reels->lastPage(),
                    'per_page' => $reels->perPage(),
                    'total' => $reels->total(),
                ],
            ],
        ]);
    }

    public function show(Request $request, string $id)
    {
        $reel = Reel::with('user')->withCount('comments')->findOrFail($id);
        $viewerReactions = $request->user()
            ? $this->viewerReactionsMap($request->user(), [(int) $id])[(int) $id] ?? null
            : null;

        return response()->json([
            'success' => true,
            'data' => $this->payload($reel, $viewerReactions),
        ]);
    }

    public function view(string $id)
    {
        $reel = Reel::findOrFail($id);
        $reel->increment('view_count');

        return response()->json([
            'success' => true,
            'data' => ['view_count' => $reel->fresh()->view_count],
        ]);
    }

    public function comments(Request $request, string $id)
    {
        $reel = Reel::findOrFail($id);
        $comments = $reel->comments()
            ->with('user:id,name,user_name,media')
            ->latest()
            ->paginate(30);

        $items = $comments->getCollection()->map(function (ReelComment $c) {
            $u = $c->user;
            return [
                'id' => (string) $c->id,
                'body' => $c->body,
                'created_at' => optional($c->created_at)->toIso8601String(),
                'user' => $u ? [
                    'id' => (string) $u->id,
                    'name' => $u->name,
                    'user_name' => $u->user_name,
                    'avatar_url' => $u->media,
                ] : null,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'items' => $items,
                'comment_count' => $reel->comments()->count(),
                'pagination' => [
                    'current_page' => $comments->currentPage(),
                    'last_page' => $comments->lastPage(),
                ],
            ],
        ]);
    }

    public function storeComment(Request $request, string $id)
    {
        $request->validate(['body' => ['required', 'string', 'max:2000']]);
        $reel = Reel::findOrFail($id);
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $comment = $reel->comments()->create([
            'user_id' => $user->id,
            'body' => trim($request->input('body')),
        ]);
        $comment->load('user:id,name,user_name,media');

        $u = $comment->user;
        return response()->json([
            'success' => true,
            'message' => 'Comment added',
            'data' => [
                'id' => (string) $comment->id,
                'body' => $comment->body,
                'created_at' => optional($comment->created_at)->toIso8601String(),
                'user' => $u ? [
                    'id' => (string) $u->id,
                    'name' => $u->name,
                    'user_name' => $u->user_name,
                    'avatar_url' => $u->media,
                ] : null,
                'comment_count' => $reel->comments()->count(),
            ],
        ], 201);
    }

    /** @return array<int, array{like: bool, dislike: bool, favorite: bool}> */
    private function viewerReactionsMap($user, array $reelIds): array
    {
        if (! $user || empty($reelIds)) {
            return [];
        }
        $rows = ReelReaction::where('user_id', $user->id)
            ->whereIn('reel_id', $reelIds)
            ->get(['reel_id', 'type']);
        $map = [];
        foreach ($reelIds as $reelId) {
            $map[$reelId] = ['like' => false, 'dislike' => false, 'favorite' => false];
        }
        foreach ($rows as $row) {
            $map[$row->reel_id][$row->type] = true;
        }
        return $map;
    }

    public function store(Request $request)
    {
        $request->validate([
            'media' => ['required', 'file', 'mimetypes:video/*,image/*'],
            'caption' => ['nullable', 'string', 'max:2000'],
            'hashtags' => ['nullable', 'array'],
            'hashtags.*' => ['string', 'max:64'],
            'visibility' => ['nullable', 'string', 'max:20'],
        ]);

        $user = $request->user();
        $path = $request->file('media')->store('reels', 'public');

        $reel = Reel::create([
            'user_id' => $user->id,
            'media_path' => $path,
            'caption' => $request->input('caption'),
            'hashtags' => $request->input('hashtags'),
            'visibility' => $request->input('visibility', 'public'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Reel created',
            'data' => $this->payload($reel->fresh('user')),
        ], 201);
    }

    /** @param array{like: bool, dislike: bool, favorite: bool}|null $viewerReactions */
    protected function payload(Reel $reel, ?array $viewerReactions = null): array
    {
        $user = $reel->user;
        $mediaUrl = $reel->media_path && ! str_starts_with((string) $reel->media_path, 'http')
            ? Storage::disk('public')->url($reel->media_path)
            : $reel->media_path;

        $commentCount = isset($reel->comments_count) ? (int) $reel->comments_count : $reel->comments()->count();
        $data = [
            'id' => (string) $reel->id,
            'user_id' => (string) $reel->user_id,
            'media_url' => $mediaUrl,
            'caption' => $reel->caption,
            'hashtags' => $reel->hashtags ?? [],
            'visibility' => $reel->visibility,
            'like_count' => $reel->like_count,
            'view_count' => $reel->view_count,
            'comment_count' => $commentCount,
            'created_at' => optional($reel->created_at)->toIso8601String(),
            'user' => $user ? [
                'id' => $user->id,
                'name' => $user->name,
                'user_name' => $user->user_name,
                'media' => $user->media,
            ] : null,
        ];

        if ($viewerReactions !== null) {
            $data['is_liked'] = $viewerReactions['like'];
            $data['is_disliked'] = $viewerReactions['dislike'];
            $data['is_favorite'] = $viewerReactions['favorite'];
        }

        return $data;
    }
}

