<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Verification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function root(Request $request)
    {
        // Compatibility endpoint: the Flutter onboarding service may POST to /api/auth (empty path).
        return response()->json([
            'message' => 'Auth endpoint reachable',
            'success' => true,
        ]);
    }

    public function signup(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'number' => ['nullable', 'string', 'max:32'],
            // Onboarding fields that Flutter may send during registration:
            'gender' => ['nullable', 'string', 'max:16'],
            'goal' => ['nullable', 'string', 'max:64'],
            'fitness_level' => ['nullable', 'string', 'max:32'],
            'birth_year' => ['nullable', 'integer', 'min:1900', 'max:2100'],
            'age' => ['nullable', 'integer', 'min:1', 'max:150'],
            'height_cm' => ['nullable', 'integer', 'min:30', 'max:300'],
            'weight_kg' => ['nullable', 'integer', 'min:10', 'max:500'],
            'is_ready' => ['nullable'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone' => $data['number'] ?? null,
            'fitness_level' => isset($data['fitness_level']) ? strtolower(trim((string) $data['fitness_level'])) : null,
            'gender' => isset($data['gender']) ? strtolower(trim((string) $data['gender'])) : null,
            'goal' => isset($data['goal']) ? trim((string) $data['goal']) : null,
            'height' => isset($data['height_cm']) ? (string) $data['height_cm'] : null,
            'weight' => isset($data['weight_kg']) ? (string) $data['weight_kg'] : null,
            'user_name' => \Illuminate\Support\Str::lower(\Illuminate\Support\Str::slug($data['name'])).'_'.random_int(100, 999),
        ]);

        // Generate OTP for optional verification flows in the app.
        $otp = $this->issueOtp(email: $user->email, type: 'signup');

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'Signup successful',
            'token' => $token,
            'otp' => $otp,
            'data' => [
                'user' => $this->userPayload($user),
            ],
        ]);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
            'data' => [
                'user' => $this->userPayload($user),
            ],
        ]);
    }

    public function signin(Request $request)
    {
        return $this->login($request);
    }

    public function forgotPassword(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $otp = $this->issueOtp(email: $data['email'], type: 'forgot');

        return response()->json([
            'message' => 'OTP sent',
            'otp' => $otp,
        ]);
    }

    public function verifySignupOtp(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'string'],
        ]);

        $this->consumeOtp(email: $data['email'], type: 'signup', otp: $data['otp']);

        return response()->json([
            'message' => 'OTP verified',
        ]);
    }

    public function verifyForgotOtp(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'string'],
        ]);

        $this->consumeOtp(email: $data['email'], type: 'forgot', otp: $data['otp'], markConsumed: false);

        return response()->json([
            'message' => 'OTP verified',
        ]);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'string'],
            'password' => ['nullable', 'string', 'min:6'],
            'new_password' => ['nullable', 'string', 'min:6'],
            'confirm_password' => ['nullable', 'string', 'min:6'],
        ]);

        $newPassword = $data['new_password'] ?? $data['password'] ?? null;
        if (! $newPassword) {
            throw ValidationException::withMessages([
                'password' => ['New password is required.'],
            ]);
        }

        if (isset($data['confirm_password']) && $data['confirm_password'] !== $newPassword) {
            throw ValidationException::withMessages([
                'confirm_password' => ['Passwords do not match.'],
            ]);
        }

        $this->consumeOtp(email: $data['email'], type: 'forgot', otp: $data['otp']);

        $user = User::where('email', $data['email'])->first();
        if (! $user) {
            throw ValidationException::withMessages([
                'email' => ['User not found.'],
            ]);
        }

        $user->forceFill(['password' => $newPassword])->save();

        return response()->json([
            'message' => 'Password reset successful',
        ]);
    }

    public function sendChangePasswordOtp(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $otp = $this->issueOtp(email: $data['email'], type: 'change_password');

        return response()->json([
            'message' => 'OTP sent',
            'otp' => $otp,
        ]);
    }

    public function verifyChangePasswordOtp(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'string'],
        ]);

        $this->consumeOtp(email: $data['email'], type: 'change_password', otp: $data['otp'], markConsumed: false);

        return response()->json([
            'message' => 'OTP verified',
        ]);
    }

    public function changePassword(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:6'],
            'confirm_password' => ['required', 'string', 'min:6'],
        ]);

        if ($data['new_password'] !== $data['confirm_password']) {
            throw ValidationException::withMessages([
                'confirm_password' => ['Passwords do not match.'],
            ]);
        }

        $this->consumeOtp(email: $data['email'], type: 'change_password', otp: $data['otp']);

        $user = User::where('email', $data['email'])->first();
        if (! $user) {
            throw ValidationException::withMessages([
                'email' => ['User not found.'],
            ]);
        }

        $user->forceFill(['password' => $data['new_password']])->save();

        return response()->json([
            'message' => 'Password changed successfully',
        ]);
    }

    public function confirmPassword(Request $request)
    {
        // Kept for compatibility with the Flutter client; treated as changePassword.
        return $this->changePassword($request);
    }

    private function issueOtp(string $email, string $type): string
    {
        $otp = (string) random_int(100000, 999999);

        Verification::create([
            'email' => $email,
            'verification_code' => $otp,
            'token' => $type,
            'expires_at' => now()->addMinutes(10),
        ]);

        return $otp;
    }

    private function consumeOtp(string $email, string $type, string $otp, bool $markConsumed = true): void
    {
        $row = Verification::query()
            ->where('email', $email)
            ->where('token', $type)
            ->where('verification_code', $otp)
            ->orderByDesc('id')
            ->first();

        if (! $row || ($row->expires_at && $row->expires_at->isPast())) {
            throw ValidationException::withMessages([
                'otp' => ['Invalid or expired OTP.'],
            ]);
        }

        if ($markConsumed) {
            $row->delete();
        }
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'user_name' => $user->user_name,
            'bio' => $user->bio,
            'fitness_level' => $user->fitness_level,
            'gender' => $user->gender,
            'goal' => $user->goal,
            'date_of_birth' => $user->date_of_birth?->format('Y-m-d'),
            'height' => $user->height,
            'weight' => $user->weight,
            'media' => $user->media,
        ];
    }
}

