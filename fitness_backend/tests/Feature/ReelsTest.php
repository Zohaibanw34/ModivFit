<?php

namespace Tests\Feature;

use App\Models\Reel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReelsTest extends TestCase
{
    use RefreshDatabase;

    protected function createUser(): User
    {
        return User::create([
            'name' => 'Test User',
            'email' => 'user@example.com',
            'password' => 'password',
            'user_name' => 'testuser',
        ]);
    }

    protected function createReel(User $user): Reel
    {
        return Reel::create([
            'user_id' => $user->id,
            'media_path' => 'reels/test.mp4',
            'caption' => 'Test reel',
            'hashtags' => ['test'],
            'visibility' => 'public',
            'like_count' => 0,
            'view_count' => 0,
        ]);
    }

    public function test_reels_index_returns_expected_shape(): void
    {
        $user = $this->createUser();
        $this->createReel($user);

        $response = $this
            ->actingAs($user, 'sanctum')
            ->getJson('/api/reels');

        $response
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'items' => [
                        [
                            'id',
                            'user_id',
                            'media_url',
                            'caption',
                            'like_count',
                            'view_count',
                            'comment_count',
                            'created_at',
                        ],
                    ],
                    'pagination' => [
                        'current_page',
                        'last_page',
                        'per_page',
                        'total',
                    ],
                ],
            ]);
    }

    public function test_toggle_reel_like_updates_flags(): void
    {
        $user = $this->createUser();
        $reel = $this->createReel($user);

        $response = $this
            ->actingAs($user, 'sanctum')
            ->postJson("/api/reels/{$reel->id}/reactions/like", [
                'is_active' => true,
            ]);

        $response
            ->assertStatus(200)
            ->assertJsonPath('ok', true)
            ->assertJsonStructure([
                'data' => [
                    'reel_id',
                    'like_count',
                    'is_liked',
                ],
            ]);
    }

    public function test_reel_comments_shape(): void
    {
        $user = $this->createUser();
        $reel = $this->createReel($user);

        $this
            ->actingAs($user, 'sanctum')
            ->postJson("/api/reels/{$reel->id}/comments", [
                'body' => 'Nice!',
            ])
            ->assertStatus(201);

        $response = $this
            ->actingAs($user, 'sanctum')
            ->getJson("/api/reels/{$reel->id}/comments");

        $response
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'items' => [
                        [
                            'id',
                            'body',
                            'created_at',
                            'user' => [
                                'id',
                                'name',
                                'user_name',
                                'avatar_url',
                            ],
                        ],
                    ],
                    'comment_count',
                    'pagination' => [
                        'current_page',
                        'last_page',
                    ],
                ],
            ]);
    }
}

