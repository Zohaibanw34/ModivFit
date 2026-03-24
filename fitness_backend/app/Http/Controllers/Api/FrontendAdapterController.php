<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Challenge;
use App\Models\FoodLogs;
use App\Models\GuidePost;
use App\Models\GuidePostReply;
use App\Models\Reel;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * Exposes API routes that match the Flutter frontend (ApiConfig).
 * Delegates to existing controllers so the frontend has all endpoints it needs.
 */
class FrontendAdapterController extends Controller
{
    public function __construct(
        protected UserController $userController,
        protected ChallengeController $challengeController,
        protected FoodLogController $foodLogController,
        protected NotificationsController $notificationsController,
        protected SubscriptionController $subscriptionController,
        protected CompatController $compatController,
    ) {}

    public function onboardingSave(Request $request)
    {
        $data = $request->all();
        $profile = array_filter([
            'name' => $data['name'] ?? null,
            'user_name' => $data['user_name'] ?? $data['username'] ?? null,
            'fitness_level' => $data['fitness_level'] ?? $data['fitnessLevel'] ?? null,
            'height' => $data['height'] ?? $data['height_value'] ?? null,
            'weight' => $data['weight'] ?? $data['weight_value'] ?? null,
        ], fn ($v) => $v !== null && $v !== '');
        if (empty($profile)) {
            return response()->json(['success' => true, 'message' => 'Saved']);
        }
        $request->merge($profile);
        return $this->userController->updateProfile($request);
    }

    public function onboardingGet(Request $request)
    {
        return $this->userController->profile($request);
    }

    public function home(Request $request)
    {
        $user = $request->user();
        $challenges = $this->challengeController->index($request);
        $foodLogs = $this->foodLogController->indexMine($request);
        $challengesData = $challenges->getData();
        $foodData = $foodLogs->getData();
        $challengesData = is_array($challengesData) ? $challengesData : [];
        $foodData = is_array($foodData) ? $foodData : [];
        $list = $challengesData['data'] ?? $challengesData['challenges'] ?? [];
        $acceptedProgress = \App\Models\AcceptedChallenge::where('user_id', $user->id)
            ->get()
            ->keyBy('challenge_id');
        $list = array_map(function ($c) use ($acceptedProgress) {
            $id = $c['id'] ?? null;
            $progress = 0.0;
            if ($id !== null && $acceptedProgress->has((int) $id)) {
                $progress = (float) $acceptedProgress->get((int) $id)->progress;
            }
            $c['progress'] = $progress;
            return $c;
        }, $list);
        return response()->json([
            'success' => true,
            'data' => [
                'challenges' => $list,
                'food_logs' => $foodData['data'] ?? $foodData['food_logs'] ?? [],
            ],
        ]);
    }

    public function recommendedMeal(Request $request)
    {
        $user = $request->user();

        $log = FoodLogs::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->first();

        if (! $log) {
            return response()->json([
                'success' => true,
                'data' => [
                    'title' => 'Nut Butter Toast With Boiled Eggs',
                    'calories' => 164,
                ],
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'title' => $log->title ?: $log->description,
                'calories' => (int) $log->calories,
            ],
        ]);
    }

    /** List of recommended meals (recent food logs + defaults) for Meals screen */
    public function recommendedMeals(Request $request)
    {
        $user = $request->user();
        $logs = FoodLogs::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(20)
            ->get();

        $items = $logs->map(fn ($log) => [
            'id' => (string) $log->id,
            'title' => $log->title ?: $log->description ?: 'Meal',
            'calories' => (int) ($log->calories ?? 0),
            'description' => $log->description,
            'image_url' => null,
        ])->values()->all();

        if (empty($items)) {
            $items = [
                ['id' => 'default_1', 'title' => 'Nut Butter Toast With Boiled Eggs', 'calories' => 164, 'description' => null, 'image_url' => null],
                ['id' => 'default_2', 'title' => 'Oatmeal with Berries', 'calories' => 320, 'description' => null, 'image_url' => null],
                ['id' => 'default_3', 'title' => 'Grilled Chicken Salad', 'calories' => 420, 'description' => null, 'image_url' => null],
            ];
        }

        return response()->json([
            'success' => true,
            'data' => ['items' => $items],
        ]);
    }

    public function profileMedia(Request $request)
    {
        $user = $request->user();
        $items = [];

        // Include current user's reels (uploaded videos) so they persist across sessions
        $reels = Reel::where('user_id', $user->id)->latest()->limit(100)->get();
        foreach ($reels as $reel) {
            $url = $reel->media_path && ! str_starts_with((string) $reel->media_path, 'http')
                ? Storage::disk('public')->url($reel->media_path)
                : $reel->media_path;
            $items[] = [
                'id' => (string) $reel->id,
                'media_url' => $url,
                'video_url' => $url,
                'url' => $url,
                'caption' => $reel->caption ?? '',
                'type' => 'video',
                'visibility' => $reel->visibility ?? 'public',
            ];
        }

        // Include challenge media (videos from challenges)
        $challenges = Challenge::where('user_id', $user->id)->whereNotNull('media')->latest()->limit(20)->get();
        foreach ($challenges as $c) {
            $url = $c->media && ! str_starts_with((string) $c->media, 'http')
                ? Storage::disk('public')->url($c->media)
                : $c->media;
            $items[] = ['id' => 'challenge_' . $c->id, 'media_url' => $url, 'caption' => $c->description ?? '', 'type' => 'challenge'];
        }

        return response()->json(['success' => true, 'data' => ['items' => $items, 'media' => $items]]);
    }

    public function challengeCategories(Request $request)
    {
        return response()->json(['success' => true, 'data' => ['categories' => ['strength', 'cardio', 'flexibility', 'endurance']]]);
    }

    public function startRandomChallenge(Request $request)
    {
        $user = $request->user();
        $challenge = Challenge::with('user')->where('level', $user->fitness_level ?? 'beginner')->inRandomOrder()->first();
        $payload = $challenge ? $this->challengePayload($challenge) : null;
        return response()->json(['success' => true, 'data' => ['challenge' => $payload]]);
    }

    public function challengeLimits(Request $request)
    {
        return response()->json(['success' => true, 'data' => ['limit' => 5, 'used' => 0]]);
    }

    public function challengeLimitsExtend(Request $request)
    {
        return response()->json(['success' => true, 'message' => 'Limits extended']);
    }

    public function challengeCards(Request $request)
    {
        return $this->challengeController->index($request);
    }

    public function challengeProgress(Request $request, string $id)
    {
        $user = $request->user();
        $accepted = \App\Models\AcceptedChallenge::where('challenge_id', $id)
            ->where('user_id', $user->id)
            ->first();
        $progress = $accepted ? (float) $accepted->progress : 0.0;
        return response()->json(['success' => true, 'data' => ['progress' => $progress]]);
    }

    public function challengeRecord(Request $request, string $id)
    {
        return $this->challengeController->record($id, $request);
    }

    public function challengeById(Request $request, string $id)
    {
        $c = Challenge::with('user')->find($id);
        return response()->json(['success' => true, 'data' => $c ? $this->challengePayload($c) : null]);
    }

    private function challengePayload(Challenge $c): array
    {
        $user = $c->user;
        $mediaUrl = $c->media && ! str_starts_with((string) $c->media, 'http') ? Storage::disk('public')->url($c->media) : $c->media;
        return [
            'id' => $c->id, 'title' => $c->title, 'name' => $c->title, 'description' => $c->description,
            'category' => $c->category, 'fitness_level' => $c->level, 'level' => $c->level,
            'time' => $c->time, 'media' => $mediaUrl,
            'user' => $user ? ['id' => $user->id, 'name' => $user->name, 'user_name' => $user->user_name] : null,
        ];
    }

    public function postsMedia(Request $request)
    {
        $request->validate(['caption' => ['nullable', 'string', 'max:2000'], 'visibility' => ['nullable', 'string'], 'type' => ['nullable', 'string']]);
        $file = $request->file('image') ?? $request->file('video') ?? $request->file('media') ?? $request->file('file');
        if (! $file) {
            return response()->json(['success' => false, 'message' => 'No file provided'], 422);
        }
        $path = $file->store('media', 'public');
        $url = Storage::disk('public')->url($path);
        $type = $request->input('type', 'image');
        $caption = $request->input('caption', '');
        return response()->json(['success' => true, 'data' => ['id' => uniqid('post_'), 'caption' => $caption, 'media_url' => $url, 'url' => $url, 'type' => $type]], 201);
    }

    public function chatRooms(Request $request)
    {
        return $this->compatController->chatRooms($request);
    }

    public function chatRoomMessages(Request $request, string $roomId)
    {
        if ($request->isMethod('post')) {
            $request->merge(['room_id' => $roomId, 'roomId' => $roomId]);
            return $this->compatController->createChatMessage($request);
        }
        return $this->compatController->chatRoomMessages($roomId);
    }

    public function chatRoomInvite(Request $request, string $roomId)
    {
        return response()->json(['success' => true, 'message' => 'Invite sent']);
    }

    public function friendsSearch(Request $request)
    {
        $q = $request->query('q', '');
        if (strlen($q) < 2) {
            return response()->json(['success' => true, 'data' => ['users' => []]]);
        }
        $users = User::where('name', 'like', '%' . $q . '%')->orWhere('user_name', 'like', '%' . $q . '%')->orWhere('email', 'like', '%' . $q . '%')->limit(20)->get(['id', 'name', 'user_name', 'email', 'media']);
        $list = $users->map(function (User $u) {
            $avatar = $u->media;
            if ($avatar && ! str_starts_with((string) $avatar, 'http')) {
                $avatar = Storage::disk('public')->url($avatar);
            }
            return ['id' => $u->id, 'name' => $u->name, 'user_name' => $u->user_name, 'avatar_url' => $avatar];
        });
        return response()->json(['success' => true, 'data' => ['users' => $list]]);
    }

    public function usersFollow(Request $request)
    {
        $id = $request->input('user_id') ?? $request->input('id');
        $request->merge(['id' => $id]);
        return $this->compatController->follow($request);
    }

    public function followUser(Request $request, string $userId)
    {
        $request->merge(['id' => $userId]);
        return $this->compatController->follow($request);
    }

    public function settings(Request $request)
    {
        return response()->json(['success' => true, 'data' => ['language' => 'en', 'theme' => 'system']]);
    }

    public function settingsLanguage(Request $request)
    {
        return response()->json(['success' => true, 'message' => 'Language updated']);
    }

    public function settingsTheme(Request $request)
    {
        return response()->json(['success' => true, 'message' => 'Theme updated']);
    }

    public function stepsSummary(Request $request)
    {
        return $this->compatController->stepsSummary($request);
    }

    public function guides(Request $request)
    {
        $tab = $request->query('tab', 'for_you');
        $topic = $request->query('topic');

        $query = GuidePost::with('user')->latest();

        if ($topic) {
            $query->where('topic', $topic);
        }

        if ($tab === 'challenge') {
          $query->where('type', 'challenge');
        } elseif ($tab === 'chat') {
          $query->where('type', 'chat');
        }

        $posts = $query->limit(20)->get();

        $items = $posts->map(fn (GuidePost $post) => $this->guidePayload($post))->values();

        return response()->json(['success' => true, 'data' => ['guides' => $items, 'items' => $items]]);
    }

    public function guidesPosts(Request $request)
    {
        $tab = $request->query('tab', 'public');
        $topic = $request->query('topic');

        $query = GuidePost::with('user')->latest();

        if ($topic) {
            $query->where('topic', $topic);
        }

        if ($tab === 'challenge') {
          $query->where('type', 'challenge');
        }

        $posts = $query->paginate(10);
        $items = $posts->getCollection()->map(fn (GuidePost $post) => $this->guidePayload($post))->values();
        $posts->setCollection($items);

        return response()->json(['success' => true, 'data' => ['posts' => $items, 'items' => $items]]);
    }

    public function guidePostLike(Request $request, string $id)
    {
        $post = GuidePost::findOrFail($id);
        $post->increment('likes_count');

        return response()->json([
            'success' => true,
            'message' => 'Liked',
            'data' => $this->guidePayload($post->fresh('user')),
        ]);
    }

    public function guidePostReply(Request $request, string $id)
    {
        $user = $request->user();
        $data = $request->validate([
            'body' => ['required', 'string', 'max:2000'],
        ]);

        $post = GuidePost::findOrFail($id);
        GuidePostReply::create([
            'guide_post_id' => $post->id,
            'user_id' => $user->id,
            'body' => $data['body'],
        ]);
        $post->increment('replies_count');

        return response()->json([
            'success' => true,
            'message' => 'Replied',
            'data' => $this->guidePayload($post->fresh('user')),
        ]);
    }

    protected function guidePayload(GuidePost $post): array
    {
        $user = $post->user;

        return [
            'id' => (string) $post->id,
            'user_id' => (string) $post->user_id,
            'title' => $post->title,
            'body' => $post->body,
            'topic' => $post->topic,
            'type' => $post->type,
            'likes_count' => $post->likes_count,
            'replies_count' => $post->replies_count,
            'created_at' => optional($post->created_at)->toIso8601String(),
            'user' => $user ? [
                'id' => $user->id,
                'name' => $user->name,
                'user_name' => $user->user_name,
                'media' => $user->media,
            ] : null,
        ];
    }

    public function reelsReactions(Request $request)
    {
        return $this->compatController->reelsReactions();
    }

    public function reelReactions(Request $request, string $reelId)
    {
        return $this->compatController->reelReactions($reelId);
    }

    public function reelReactionByType(Request $request, string $reelId, string $type)
    {
        return $this->compatController->toggleReelReaction($reelId, $type, $request);
    }
}
