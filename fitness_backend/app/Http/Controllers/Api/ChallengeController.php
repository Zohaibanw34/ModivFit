<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AcceptedChallenge;
use App\Models\Challenge;
use App\Models\Chats;
use App\Models\Comments;
use App\Models\ChallengeLikes;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ChallengeController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $myChallenges = AcceptedChallenge::where('user_id', $user->id)->where('status', 'active')->pluck('challenge_id');

        $challenges = Challenge::with('user')
            ->where('user_id', $user->id)
            ->orWhereIn('id', $myChallenges)
            ->orderByDesc('created_at')
            ->paginate(5);

        $items = $challenges->getCollection()->map(fn (Challenge $c) => $this->challengePayload($c))->values();
        $challenges->setCollection($items);

        return response()->json($challenges);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'category' => ['nullable', 'string'],
            'fitness_level' => ['required', 'string'],
            'description' => ['required', 'string'],
            'media' => ['nullable', 'file'],
            'time' => ['nullable', 'numeric'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 404);
        }

        $user = $request->user();
        $challenge = Challenge::create([
            'user_id' => $user->id,
            'title' => $request->name,
            'category' => $request->category,
            'level' => $request->fitness_level,
            'description' => $request->description,
            'time' => $request->time,
        ]);

        if ($request->hasFile('media')) {
            $path = $request->file('media')->store('challenges', 'public');
            $challenge->media = $path;
            $challenge->save();
        }

        Chats::create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'is_admin' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Challenge created successfully',
            'challenge' => $this->challengePayload($challenge->fresh('user')),
        ], 201);
    }

    public function show(Request $request)
    {
        $user = $request->user();
        $myChallenges = AcceptedChallenge::where('user_id', $user->id)->pluck('challenge_id');
        $challenges = Challenge::with('user')
            ->whereNotIn('id', $myChallenges)
            ->where('level', $user->fitness_level)
            ->latest()
            ->paginate(15);

        $items = $challenges->getCollection()->map(fn (Challenge $c) => $this->challengePayload($c))->values();
        $challenges->setCollection($items);

        return response()->json($challenges);
    }

    public function current(Request $request)
    {
        $user = $request->user();
        $accepted = AcceptedChallenge::with('challenge')->where('user_id', $user->id)->where('status', 'active')->latest()->first();

        return response()->json([
            'success' => true,
            'data' => [
                'current' => $accepted ? $this->challengePayload($accepted->challenge) : null,
            ],
        ]);
    }

    public function accept(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'challenge_id' => ['required', 'integer', 'exists:challenges,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $user = $request->user();
        $userId = $user?->id ?? null;
        if (! $userId) {
            return response()->json([
                'success' => false,
                'message' => 'Authenticated user required',
            ], 401);
        }

        $challengeId = (int) $request->challenge_id;

        if (AcceptedChallenge::where('user_id', $userId)->where('challenge_id', $challengeId)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Challenge already accepted by this user',
            ], 409);
        }

        AcceptedChallenge::create([
            'user_id' => $userId,
            'challenge_id' => $challengeId,
        ]);

        Chats::create([
            'user_id' => $userId,
            'challenge_id' => $challengeId,
            'is_admin' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Challenge accepted successfully',
        ], 201);
    }

    public function record(string $id, Request $request)
    {
        $user = $request->user();
        $accepted = AcceptedChallenge::where('challenge_id', $id)->where('user_id', $user->id)->first();
        if ($accepted) {
            $accepted->description = $request->input('description', $accepted->description);
            $progress = $request->input('progress');
            if (is_numeric($progress)) {
                $accepted->progress = min(1.0, max(0.0, (float) $progress));
            }
            $accepted->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Progress recorded',
        ]);
    }

    public function like(Request $request)
    {
        $user = $request->user();
        $challengeId = $request->input('challenge_id');
        if (! $challengeId) {
            return response()->json(['success' => false, 'message' => 'challenge_id required'], 422);
        }

        $challenge = Challenge::findOrFail($challengeId);
        $existing = ChallengeLikes::where('challenge_id', $challenge->id)->where('user_id', $user->id)->first();
        $type = $request->input('type', 'like');

        if ($existing) {
            $existing->type = $type;
            $existing->save();
        } else {
            ChallengeLikes::create([
                'challenge_id' => $challenge->id,
                'user_id' => $user->id,
                'type' => $type,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Like updated',
        ]);
    }

    public function comment(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'challenge_id' => ['required', 'integer', 'exists:challenges,id'],
            'description' => ['required', 'string', 'max:2000'],
            'body' => ['nullable', 'string', 'max:2000'],
        ]);

        $desc = $data['description'] ?? $data['body'] ?? '';
        $comment = Comments::create([
            'user_id' => $user->id,
            'challenge_id' => $data['challenge_id'],
            'description' => $desc,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Comment added',
            'data' => $comment,
        ], 201);
    }

    protected function challengePayload(Challenge $challenge): array
    {
        $user = $challenge->user;

        return [
            'id' => (string) $challenge->id,
            'user_id' => (string) $challenge->user_id,
            'title' => $challenge->title,
            'description' => $challenge->description,
            'time' => $challenge->time,
            'media' => $challenge->media ? \Storage::disk('public')->url($challenge->media) : null,
            'category' => $challenge->category,
            'level' => $challenge->level,
            'user' => $user ? ['id' => $user->id, 'name' => $user->name, 'media' => $user->media] : null,
        ];
    }
}
