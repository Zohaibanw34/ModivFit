<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AcceptedChallenge;
use App\Models\AcceptedChallengesLikes;
use App\Models\Followers;
use App\Models\Reel;
use App\Models\User;
use App\Models\Verification;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

/**
 * FunFit-style user API: login, register, profile, update_profile, etc.
 * Responses use success + message (+ user/data) for client compatibility.
 */
class UserController extends Controller
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'string', 'email', 'exists:users,email'],
            'password' => ['required', 'string'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 404);
        }

        $user = User::where('email', $request->email)->first();
        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User logged in successfully',
            'token' => $token,
            'user' => $this->userPayload($user),
        ], 200);
    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'phone' => ['nullable', 'string', 'max:32'],
            'number' => ['nullable', 'string', 'max:32'],
            'country' => ['nullable', 'string', 'max:64'],
            'gender' => ['nullable', 'string', 'max:16'],
            'date_of_birth' => ['nullable', 'date'],
            'height' => ['nullable', 'numeric'],
            'weight' => ['nullable', 'numeric'],
            'height_cm' => ['nullable', 'numeric'],
            'weight_kg' => ['nullable', 'numeric'],
            'fitness_level' => ['nullable', 'string', 'max:32'],
            'goal' => ['nullable', 'string', 'max:64'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 404);
        }

        $phone = $request->phone ?? $request->number ?? null;
        $height = $request->height ?? $request->height_cm ?? null;
        $weight = $request->weight ?? $request->weight_kg ?? null;
        $dob = $request->date_of_birth ?? null;
        $birthYear = $dob ? (int) date('Y', strtotime($dob)) : null;
        $age = $request->age ?? ($dob ? now()->diffInYears(\Carbon\Carbon::parse($dob)) : null);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => $request->password,
            'phone' => $phone,
            'gender' => $request->gender ? strtolower(trim($request->gender)) : null,
            'date_of_birth' => $birthYear ? \Carbon\Carbon::createFromDate($birthYear, 1, 1) : null,
            'height' => $height ? (string) $height : null,
            'weight' => $weight ? (string) $weight : null,
            'fitness_level' => $request->fitness_level ? strtolower(trim($request->fitness_level)) : null,
            'goal' => $request->goal ? trim($request->goal) : null,
            'user_name' => $this->generateUserName($request->name),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully',
            'token' => $token,
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function loginUsingToken(Request $request)
    {
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User not authenticated or token is invalid',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'User authenticated successfully',
            'user' => $this->userPayload($user),
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()?->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    /** FunFit: user_profile */
    public function profile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'message' => 'Profile fetched',
            'user' => $this->userPayload($user),
            'data' => $this->profilePayload($user),
        ], 200);
    }

    /** FunFit: update_profile */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => ['nullable', 'string', 'max:255'],
            'username' => ['nullable', 'string', 'max:64'],
            'user_name' => ['nullable', 'string', 'max:64'],
            'bio' => ['nullable', 'string', 'max:2000'],
            'fitness_level' => ['nullable', 'string', 'max:32'],
            'fitnessLevel' => ['nullable', 'string', 'max:32'],
        ]);

        $username = $data['username'] ?? $data['user_name'] ?? null;
        if (is_string($username)) {
            $username = ltrim(trim($username), '@');
        }

        if (array_key_exists('name', $data) && is_string($data['name'])) {
            $user->name = trim($data['name']);
        }
        if ($username !== null && $username !== '') {
            $user->user_name = $username;
        }
        if (array_key_exists('bio', $data)) {
            $user->bio = is_string($data['bio']) ? $data['bio'] : null;
        }
        $fitnessLevel = $data['fitness_level'] ?? $data['fitnessLevel'] ?? null;
        if (is_string($fitnessLevel) && trim($fitnessLevel) !== '') {
            $user->fitness_level = strtolower(trim($fitnessLevel));
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile updated',
            'user' => $this->userPayload($user),
        ], 200);
    }

    /** FunFit: update_profile_img */
    public function uploadProfileImg(Request $request)
    {
        $request->validate([
            'image' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
            'media' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
        ]);

        $file = $request->file('image') ?? $request->file('media');
        if (! $file) {
            return response()->json([
                'success' => false,
                'message' => 'No image provided',
            ], 422);
        }

        $user = $request->user();
        $path = $file->store('avatars', 'public');
        $user->media = $path;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile image updated',
            'user' => $this->userPayload($user),
            'media' => \Storage::disk('public')->url($path),
        ], 200);
    }

    /** FunFit: leaderboard (POST in FunFit) */
    public function leaderBoard(Request $request)
    {
        $leaderboard = app(LeaderboardController::class);
        return $leaderboard->index($request);
    }

    /** FunFit: social_detail */
    public function social(Request $request)
    {
        $user = $request->user();
        $follower = Followers::where('followed_id', $user->id)->count();
        $following = Followers::where('follower_id', $user->id)->count();
        $totalLikes = AcceptedChallengesLikes::whereIn('accepted_challenge_id', AcceptedChallenge::where('user_id', $user->id)->pluck('id'))->where('type', 'like')->count();

        return response()->json([
            'success' => true,
            'total_likes_count' => $totalLikes,
            'follower' => $follower,
            'following' => $following,
        ], 200);
    }

    /** FunFit: send_otp / verifyEmail */
    public function verifyEmail(Request $request)
    {
        $request->validate(['email' => ['required', 'email']]);
        $email = $request->email ?? $request->email_address;
        $otp = (string) random_int(1000, 9999);
        Verification::create([
            'email' => $email,
            'verification_code' => $otp,
            'expires_at' => now()->addMinutes(10),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'OTP sent',
            'otp' => $otp,
        ], 200);
    }

    /** FunFit: validate_otp */
    public function validateOtp(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'digits:4'],
        ]);

        $row = Verification::query()
            ->where('email', $request->email)
            ->where('verification_code', $request->otp)
            ->orderByDesc('id')
            ->first();

        if (! $row || ($row->expires_at && $row->expires_at->isPast())) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ], 404);
        }

        $row->delete();

        return response()->json([
            'success' => true,
            'message' => 'OTP verified',
        ], 200);
    }

    /** FunFit: update_password */
    public function updatePassword(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'digits:4'],
            'password' => ['nullable', 'string', 'min:6'],
            'new_password' => ['nullable', 'string', 'min:6'],
        ]);

        $newPassword = $request->new_password ?? $request->password;
        if (! $newPassword) {
            return response()->json([
                'success' => false,
                'message' => 'New password is required',
            ], 422);
        }

        $row = Verification::query()
            ->where('email', $request->email)
            ->where('verification_code', $request->otp)
            ->orderByDesc('id')
            ->first();

        if (! $row || ($row->expires_at && $row->expires_at->isPast())) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP',
            ], 404);
        }

        $row->delete();
        $user = User::where('email', $request->email)->first();
        if ($user) {
            $user->forceFill(['password' => $newPassword])->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Password updated',
        ], 200);
    }

    /** FunFit: update_fitness_level */
    public function updateFitnessLevel(Request $request)
    {
        $user = $request->user();
        $level = $request->input('fitness_level') ?? $request->input('level');
        if (is_string($level) && trim($level) !== '') {
            $user->fitness_level = strtolower(trim($level));
            $user->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Fitness level updated',
            'user' => $this->userPayload($user),
        ], 200);
    }

    /** FunFit: update_fcm */
    public function fcmUpdate(Request $request)
    {
        $user = $request->user();
        $fcm = $request->input('fcm_token') ?? $request->input('fcm');
        if (is_string($fcm) && trim($fcm) !== '') {
            if (Schema::hasColumn('users', 'fcm_token')) {
                $user->fcm_token = trim($fcm);
                $user->save();
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'FCM updated',
        ], 200);
    }

    private function generateUserName(string $name): string
    {
        $base = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $name));
        $base = $base ?: 'user';
        $username = $base;
        $n = 0;
        while (User::where('user_name', $username)->exists()) {
            $username = $base . (string) (++$n);
        }

        return $username;
    }

    private function userPayload(User $user): array
    {
        $mediaUrl = $user->media && ! str_starts_with($user->media, 'http')
            ? \Storage::disk('public')->url($user->media)
            : $user->media;

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'user_name' => $user->user_name,
            'username' => $user->user_name,
            'bio' => $user->bio,
            'fitness_level' => $user->fitness_level,
            'points' => $user->points ?? 0,
            'media' => $mediaUrl,
            'avatar_url' => $mediaUrl,
            'phone' => $user->phone,
            'country' => $user->country,
            'gender' => $user->gender,
            'date_of_birth' => $user->date_of_birth?->format('Y-m-d'),
        ];
    }

    private function profilePayload(User $user): array
    {
        return [
            'user' => $this->userPayload($user),
            'name' => $user->name,
            'email' => $user->email,
            'username' => $user->user_name,
            'bio' => $user->bio,
            'fitness_level' => $user->fitness_level,
            'avatar_url' => $this->userPayload($user)['media'] ?? null,
        ];
    }

    /** Public profile by user id (for viewing from reels etc.) */
    public function showPublic(Request $request, string $userId)
    {
        $user = User::find($userId);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }

        $viewer = $request->user();
        $isFollowing = $viewer && Followers::where('follower_id', $viewer->id)
            ->where('followed_id', $user->id)->exists();

        $reels = Reel::where('user_id', $user->id)->latest()->limit(50)->get();
        $reelItems = $reels->map(function (Reel $reel) {
            $mediaUrl = $reel->media_path && ! str_starts_with((string) $reel->media_path, 'http')
                ? Storage::disk('public')->url($reel->media_path)
                : $reel->media_path;
            return [
                'id' => (string) $reel->id,
                'media_url' => $mediaUrl,
                'caption' => $reel->caption,
                'like_count' => $reel->like_count,
                'comment_count' => $reel->comments()->count(),
            ];
        });

        $payload = $this->userPayload($user);
        unset($payload['email']); // don't expose email on public profile

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $payload,
                'is_following' => $isFollowing,
                'reels' => $reelItems,
            ],
        ]);
    }
}
