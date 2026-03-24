<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class CompatController extends Controller
{
    // Challenges
    public function createChallenge(Request $request)
    {
        return response()->json([
            'message' => 'Challenge created',
            'data' => [
                'id' => '1',
                'payload' => $request->all(),
            ],
        ]);
    }

    public function deleteChallenge(string $id)
    {
        return response()->json([
            'message' => 'Challenge deleted',
            'data' => [
                'id' => $id,
            ],
        ]);
    }

    public function challengeCategories()
    {
        return response()->json([
            'message' => 'Challenge categories fetched',
            'data' => [
                'categories' => [],
                'items' => [],
            ],
        ]);
    }

    public function challengesIndex()
    {
        return response()->json([
            'message' => 'Challenges fetched',
            'data' => [
                'challenges' => [],
                'items' => [],
            ],
        ]);
    }

    public function currentChallenge()
    {
        return response()->json([
            'message' => 'Current challenge fetched',
            'data' => [
                'current' => null,
            ],
        ]);
    }

    public function challengeById(string $id)
    {
        return response()->json([
            'message' => 'Challenge fetched',
            'data' => [
                'id' => $id,
            ],
        ]);
    }

    public function startRandomChallenge(Request $request)
    {
        return response()->json([
            'message' => 'Challenge started',
            'data' => [
                'current' => null,
            ],
        ]);
    }

    public function recordChallenge(string $id, Request $request)
    {
        return response()->json([
            'message' => 'Challenge progress recorded',
            'data' => [
                'id' => $id,
                'payload' => $request->all(),
            ],
        ]);
    }

    public function challengeLimits()
    {
        return response()->json([
            'message' => 'Challenge limits fetched',
            'data' => [
                'limits' => new \stdClass(),
            ],
        ]);
    }

    public function extendChallengeLimits(Request $request)
    {
        return response()->json([
            'message' => 'Challenge limits updated',
            'data' => [
                'payload' => $request->all(),
            ],
        ]);
    }

    public function challengeCards()
    {
        return response()->json([
            'message' => 'Challenge cards fetched',
            'data' => [
                'cards' => [],
                'items' => [],
            ],
        ]);
    }

    // Guides
    public function guides(Request $request)
    {
        return response()->json([
            'message' => 'Guides fetched',
            'data' => [
                'guides' => [],
                'items' => [],
                'tab' => $request->query('tab'),
                'topic' => $request->query('topic'),
            ],
        ]);
    }

    public function guidePosts(Request $request)
    {
        return response()->json([
            'message' => 'Guide posts fetched',
            'data' => [
                'posts' => [],
                'items' => [],
                'tab' => $request->query('tab'),
                'topic' => $request->query('topic'),
            ],
        ]);
    }

    public function createGuidePost(Request $request)
    {
        return response()->json([
            'message' => 'Guide post created',
            'data' => [
                'id' => '1',
                'payload' => $request->all(),
            ],
        ]);
    }

    public function likeGuidePost(string $id)
    {
        return response()->json([
            'message' => 'Post liked',
            'data' => [
                'id' => $id,
                'liked' => true,
            ],
        ]);
    }

    public function replyGuidePost(string $id, Request $request)
    {
        return response()->json([
            'message' => 'Reply added',
            'data' => [
                'id' => $id,
                'payload' => $request->all(),
            ],
        ]);
    }

    // Chat
    public function chatRooms(Request $request)
    {
        $user = $request->user();
        $chats = \App\Models\Chats::where('user_id', $user->id)->with('challenge')->orderByDesc('created_at')->get();

        return response()->json([
            'success' => true,
            'message' => 'Chats retrieved successfully',
            'data' => $chats,
        ]);
    }

    public function chatRoomInvite(string $roomId, Request $request)
    {
        return response()->json([
            'message' => 'Invite sent',
            'data' => [
                'room_id' => $roomId,
                'payload' => $request->all(),
            ],
        ]);
    }

    public function chatRoomMessages(string $roomId)
    {
        return response()->json([
            'message' => 'Messages fetched',
            'data' => [
                'room_id' => $roomId,
                'messages' => [],
                'items' => [],
            ],
        ]);
    }

    public function createChatRoomMessage(string $roomId, Request $request)
    {
        $user = $request->user();
        $challengeId = $request->input('challenge_id') ?? $roomId;
        $chat = \App\Models\Chats::where('challenge_id', $challengeId)->where('user_id', $user->id)->first();
        if (! $chat) {
            $chat = \App\Models\Chats::create([
                'user_id' => $user->id,
                'challenge_id' => $challengeId,
                'is_admin' => false,
            ]);
        }
        $msg = \App\Models\ChatMessages::create([
            'sender_id' => $user->id,
            'challenge_id' => $challengeId,
            'chat_id' => $chat->id,
            'message' => $request->input('message', ''),
            'message_type' => 'text',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Chat message sent.',
            'data' => $msg,
        ], 201);
    }

    // Friends search
    public function friendsSearch(Request $request)
    {
        return response()->json([
            'message' => 'Friends search results',
            'data' => [
                'q' => $request->query('q'),
                'users' => [],
                'items' => [],
            ],
        ]);
    }

    // Steps
    public function stepsSummary(Request $request)
    {
        $range = $request->query('range', 'week');
        $user = $request->user();
        
        // For now, return dummy data. In a real implementation, 
        // this would query a steps table or fitness tracking data
        $days = [];
        $totalSteps = 0;
        
        if ($range === 'week') {
            $days = [
                ['date' => now()->subDays(6)->format('Y-m-d'), 'steps' => rand(5000, 12000)],
                ['date' => now()->subDays(5)->format('Y-m-d'), 'steps' => rand(5000, 12000)],
                ['date' => now()->subDays(4)->format('Y-m-d'), 'steps' => rand(5000, 12000)],
                ['date' => now()->subDays(3)->format('Y-m-d'), 'steps' => rand(5000, 12000)],
                ['date' => now()->subDays(2)->format('Y-m-d'), 'steps' => rand(5000, 12000)],
                ['date' => now()->subDays(1)->format('Y-m-d'), 'steps' => rand(5000, 12000)],
                ['date' => now()->format('Y-m-d'), 'steps' => rand(5000, 12000)],
            ];
        } elseif ($range === 'month') {
            for ($i = 29; $i >= 0; $i--) {
                $days[] = [
                    'date' => now()->subDays($i)->format('Y-m-d'),
                    'steps' => rand(3000, 15000)
                ];
            }
        }
        
        $totalSteps = array_sum(array_column($days, 'steps'));

        return response()->json([
            'success' => true,
            'message' => 'Steps summary fetched',
            'data' => [
                'range' => $range,
                'total_steps' => $totalSteps,
                'steps' => $totalSteps, // For backward compatibility
                'days' => $days,
            ],
        ]);
    }

    // Reels reactions
    public function reelsReactions()
    {
        return response()->json([
            'message' => 'Reels reactions fetched',
            'data' => [
                'items' => [],
            ],
        ]);
    }

    public function reelReactions(string $reelId)
    {
        return response()->json([
            'message' => 'Reel reactions fetched',
            'data' => [
                'reel_id' => $reelId,
                'items' => [],
            ],
        ]);
    }

    public function toggleReelReaction(string $reelId, string $type, Request $request)
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $active = filter_var(
            $request->input('is_active') ?? $request->input('active') ?? false,
            FILTER_VALIDATE_BOOLEAN
        );
        $type = strtolower(trim($type));
        if (! in_array($type, ['like', 'dislike', 'favorite', 'not_interested'], true)) {
            return response()->json(['message' => 'Invalid reaction type'], 422);
        }

        $reel = \App\Models\Reel::find($reelId);
        if (! $reel) {
            return response()->json(['message' => 'Reel not found'], 404);
        }

        $existing = \App\Models\ReelReaction::where('user_id', $user->id)
            ->where('reel_id', $reel->id)
            ->where('type', $type)
            ->first();

        if ($active) {
            if (! $existing) {
                \App\Models\ReelReaction::create([
                    'user_id' => $user->id,
                    'reel_id' => $reel->id,
                    'type' => $type,
                ]);
                if ($type === 'like') {
                    $reel->increment('like_count');
                }
            }
        } else {
            if ($existing) {
                $existing->delete();
                if ($type === 'like') {
                    $reel->decrement('like_count');
                }
            }
        }

        if ($type === 'not_interested') {
            return response()->json([
                'ok' => true,
                'message' => 'Reel hidden from feed',
                'data' => ['reel_id' => (string) $reel->id],
            ]);
        }

        $reel->refresh();
        $liked = (bool) \App\Models\ReelReaction::where('user_id', $user->id)
            ->where('reel_id', $reel->id)
            ->where('type', 'like')
            ->exists();
        $disliked = (bool) \App\Models\ReelReaction::where('user_id', $user->id)
            ->where('reel_id', $reel->id)
            ->where('type', 'dislike')
            ->exists();
        $favorite = (bool) \App\Models\ReelReaction::where('user_id', $user->id)
            ->where('reel_id', $reel->id)
            ->where('type', 'favorite')
            ->exists();

        return response()->json([
            'ok' => true,
            'message' => 'Reaction updated',
            'data' => [
                'reel_id' => (string) $reel->id,
                'like_count' => $reel->like_count,
                'is_liked' => $liked,
                'is_disliked' => $disliked,
                'is_favorite' => $favorite,
            ],
        ]);
    }

    // Follow
    public function followUser(string $userId, Request $request)
    {
        $follow = $request->input('follow') ?? $request->input('is_following') ?? null;

        return response()->json([
            'message' => 'Follow updated',
            'data' => [
                'user_id' => $userId,
                'follow' => (bool) $follow,
            ],
        ]);
    }

    public function follow(Request $request)
    {
        $request->validate(['id' => ['required', 'exists:users,id']]);
        $user = $request->user();
        $followedId = (int) $request->id;

        if ($user->id === $followedId) {
            return response()->json([
                'status' => false,
                'message' => 'You cannot follow yourself.',
            ], 400);
        }

        $existing = \App\Models\Followers::where('follower_id', $user->id)->where('followed_id', $followedId)->first();
        if ($existing) {
            $existing->delete();
            return response()->json([
                'status' => false,
                'message' => 'You are not following this user.',
            ], 200);
        }

        \App\Models\Followers::create([
            'follower_id' => $user->id,
            'followed_id' => $followedId,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'You are now following this user.',
        ], 201);
    }

    // FunFit-style flat endpoints (stubs or delegates)
    public function likeAcceptedChallenge(Request $request)
    {
        return response()->json(['success' => true, 'message' => 'Like recorded', 'data' => $request->all()]);
    }

    public function likeComment(Request $request)
    {
        return response()->json(['success' => true, 'message' => 'Comment like recorded', 'data' => $request->all()]);
    }

    public function likeSubComment(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'comment_id' => ['required', 'integer', 'exists:comments,id'],
            'description' => ['required', 'string', 'max:2000'],
            'body' => ['nullable', 'string', 'max:2000'],
        ]);

        $desc = $data['description'] ?? $data['body'] ?? '';
        $subComment = \App\Models\SubComments::create([
            'user_id' => $user->id,
            'comment_id' => $data['comment_id'],
            'description' => $desc,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sub-comment added',
            'data' => $subComment,
        ], 201);
    }

    public function acceptChallengeUpload(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'accepted_challenge_id' => ['required', 'integer', 'exists:accepted_challenges,id'],
            'media' => ['required', 'file', 'mimetypes:video/*,image/*'],
            'description' => ['nullable', 'string', 'max:2000'],
        ]);

        $acceptedChallenge = \App\Models\AcceptedChallenge::where('id', $data['accepted_challenge_id'])
            ->where('user_id', $user->id)
            ->firstOrFail();

        if ($request->hasFile('media')) {
            $path = $request->file('media')->store('accepted_challenges', 'public');
            $acceptedChallenge->media = $path;
            if (isset($data['description'])) {
                $acceptedChallenge->description = $data['description'];
            }
            $acceptedChallenge->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Challenge upload recorded',
            'data' => [
                'accepted_challenge_id' => $acceptedChallenge->id,
                'media_url' => $acceptedChallenge->media ? \Storage::disk('public')->url($acceptedChallenge->media) : null,
            ],
        ]);
    }

    public function getShorts(Request $request)
    {
        // Delegate to ReelController for actual reels data
        $reelController = app(ReelController::class);
        $response = $reelController->index($request);
        $data = $response->getData(true);
        
        return response()->json([
            'success' => true,
            'data' => [
                'items' => $data['data']['items'] ?? [],
                'shorts' => $data['data']['items'] ?? [],
            ]
        ]);
    }

    public function searchVideos(Request $request)
    {
        // Add search query to request and delegate to ReelController
        $request->merge(['search' => $request->input('q') ?? $request->input('query') ?? '']);
        $reelController = app(ReelController::class);
        $response = $reelController->index($request);
        $data = $response->getData(true);
        
        return response()->json([
            'success' => true,
            'data' => [
                'items' => $data['data']['items'] ?? [],
                'q' => $request->input('q'),
            ]
        ]);
    }

    public function addRecipe(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'calories' => ['nullable', 'numeric', 'min:0'],
            'protein' => ['nullable', 'numeric', 'min:0'],
            'carbs' => ['nullable', 'numeric', 'min:0'],
            'fats' => ['nullable', 'numeric', 'min:0'],
            'type' => ['nullable', 'string'],
        ]);

        $recipe = \App\Models\FoodLogs::create([
            'user_id' => $user->id,
            'title' => $data['title'] ?? null,
            'description' => $data['description'] ?? '',
            'calories' => $data['calories'] ?? 0,
            'protein' => $data['protein'] ?? 0,
            'carbs' => $data['carbs'] ?? 0,
            'fats' => $data['fats'] ?? 0,
            'type' => $data['type'] ?? 'recipe',
            'is_recipe' => true, // Assuming we add this column, or use type
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Recipe added',
            'data' => $recipe,
        ]);
    }

    public function getRecipes(Request $request)
    {
        $user = $request->user();
        $recipes = \App\Models\FoodLogs::where('user_id', $user->id)
            ->where('type', 'recipe')
            ->orWhere('is_recipe', true)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'recipes' => $recipes,
                'items' => $recipes,
            ]
        ]);
    }

    public function addSteps(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'steps' => ['required', 'integer', 'min:0'],
            'date' => ['nullable', 'date'],
        ]);

        $date = $data['date'] ?? now()->format('Y-m-d');
        
        // In a real implementation, this would save to a steps table
        // For now, we'll store in cache as a simple demo
        $cacheKey = "user_steps_{$user->id}_{$date}";
        $existingSteps = \Cache::get($cacheKey, 0);
        $newTotal = $existingSteps + $data['steps'];
        \Cache::put($cacheKey, $newTotal, now()->addDays(30));

        return response()->json([
            'success' => true,
            'message' => 'Steps recorded',
            'data' => [
                'date' => $date,
                'steps_added' => $data['steps'],
                'total_steps' => $newTotal,
            ],
        ]);
    }

    public function report(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'type' => ['required', 'string'], // e.g., 'user', 'challenge', 'comment'
            'id' => ['required', 'integer'], // ID of the reported item
            'reason' => ['required', 'string', 'max:500'],
        ]);

        // In a real implementation, this would save to a reports table
        // For now, we'll log it and acknowledge
        \Log::info('Report submitted', [
            'user_id' => $user->id,
            'type' => $data['type'],
            'reported_id' => $data['id'],
            'reason' => $data['reason'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Report received and will be reviewed',
            'data' => [
                'type' => $data['type'],
                'id' => $data['id'],
            ],
        ]);
    }

    public function viewUserProfile(Request $request)
    {
        $user = $request->user();
        $mediaUrl = $user->media && ! str_starts_with((string) $user->media, 'http')
            ? \Storage::disk('public')->url($user->media)
            : $user->media;

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'user_name' => $user->user_name,
                'bio' => $user->bio,
                'media' => $mediaUrl,
            ],
        ]);
    }

    /** FunFit send_message: room_id in body */
    public function createChatMessage(Request $request)
    {
        $roomId = $request->input('room_id') ?? $request->input('roomId') ?? '1';
        return $this->createChatRoomMessage($roomId, $request);
    }
}

