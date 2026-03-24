<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FoodLogs;
use App\Models\FoodLogsLikes;
use App\Models\FoodLogComments;
use Illuminate\Http\Request;

class FoodLogController extends Controller
{
    public function indexPublic(Request $request)
    {
        $logs = FoodLogs::with('user')->latest()->limit(50)->get()->map(fn ($log) => $this->logPayload($log))->values();

        return response()->json([
            'success' => true,
            'data' => $logs,
        ]);
    }

    public function indexMine(Request $request)
    {
        $user = $request->user();
        $logs = FoodLogs::with('user')->where('user_id', $user->id)->latest()->limit(50)->get()->map(fn ($log) => $this->logPayload($log))->values();

        return response()->json([
            'success' => true,
            'data' => $logs,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'description' => ['nullable', 'string', 'max:2000'],
            'message' => ['nullable', 'string', 'max:2000'],
            'title' => ['nullable', 'string', 'max:255'],
            'type' => ['nullable', 'string', 'max:32'],
            'calories' => ['nullable', 'numeric'],
            'protein' => ['nullable', 'numeric'],
            'carbs' => ['nullable', 'numeric'],
            'fats' => ['nullable', 'numeric'],
        ]);

        $user = $request->user();
        $text = $request->description ?? $request->message ?? '';
        if (trim((string) $text) === '') {
            return response()->json(['success' => false, 'message' => 'description or message is required'], 422);
        }

        $log = FoodLogs::create([
            'user_id' => $user->id,
            'title' => $request->title,
            'description' => trim($text),
            'type' => $request->type,
            'calories' => $request->calories ?? 0,
            'protein' => $request->protein ?? 0,
            'carbs' => $request->carbs ?? 0,
            'fats' => $request->fats ?? 0,
        ]);

        return response()->json([
            'success' => true,
            'foodLog' => $this->logPayload($log->fresh('user')),
            'data' => $this->logPayload($log->fresh('user')),
        ], 201);
    }

    public function like(Request $request)
    {
        $user = $request->user();
        $foodLogId = $request->input('food_log_id') ?? $request->input('food_post_id');
        if (! $foodLogId) {
            return response()->json(['success' => false, 'message' => 'food_log_id required'], 422);
        }

        $log = FoodLogs::findOrFail($foodLogId);
        $existing = FoodLogsLikes::where('food_log_id', $log->id)->where('user_id', $user->id)->first();
        $type = $request->input('type', 'like');

        if ($existing) {
            $existing->delete();
            $liked = false;
        } else {
            FoodLogsLikes::create([
                'food_log_id' => $log->id,
                'user_id' => $user->id,
                'type' => $type,
            ]);
            $liked = true;
        }

        return response()->json([
            'success' => true,
            'liked' => $liked,
            'data' => $this->logPayload($log->fresh('user')),
        ]);
    }

    public function deleteLog(Request $request)
    {
        $user = $request->user();
        $id = $request->input('food_log_id') ?? $request->input('id');
        if (! $id) {
            return response()->json(['success' => false, 'message' => 'food_log_id required'], 422);
        }
        $log = FoodLogs::where('id', $id)->where('user_id', $user->id)->first();
        if (! $log) {
            return response()->json(['success' => false, 'message' => 'Food log not found'], 404);
        }
        $log->delete();

        return response()->json(['success' => true, 'message' => 'Food log deleted']);
    }

    public function comment(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'food_log_id' => ['required', 'integer', 'exists:food_logs,id'],
            'food_post_id' => ['nullable', 'integer', 'exists:food_logs,id'],
            'description' => ['required', 'string', 'max:2000'],
            'body' => ['nullable', 'string', 'max:2000'],
        ]);

        $logId = $data['food_log_id'] ?? $data['food_post_id'];
        $desc = $data['description'] ?? $data['body'] ?? '';

        $comment = FoodLogComments::create([
            'user_id' => $user->id,
            'food_log_id' => $logId,
            'description' => $desc,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Comment added',
            'data' => $comment,
        ], 201);
    }

    protected function logPayload(FoodLogs $log): array
    {
        $user = $log->user;

        return [
            'id' => (string) $log->id,
            'user_id' => (string) $log->user_id,
            'title' => $log->title,
            'description' => $log->description,
            'type' => $log->type,
            'calories' => $log->calories,
            'protein' => $log->protein,
            'carbs' => $log->carbs,
            'fats' => $log->fats,
            'user' => $user ? ['id' => $user->id, 'name' => $user->name, 'media' => $user->media] : null,
            'created_at' => optional($log->created_at)->toIso8601String(),
        ];
    }
}
