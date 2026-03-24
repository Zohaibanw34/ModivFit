<?php

namespace Tests\Feature;

use App\Models\Notifications;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HomeAndNotificationsTest extends TestCase
{
    use RefreshDatabase;

    protected function createUser(): User
    {
        return User::create([
            'name' => 'Home User',
            'email' => 'home@example.com',
            'password' => 'password',
            'user_name' => 'homeuser',
        ]);
    }

    public function test_home_endpoint_shape(): void
    {
        $user = $this->createUser();

        $response = $this
            ->actingAs($user, 'sanctum')
            ->getJson('/api/home');

        $response
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'challenges',
                    'food_logs',
                ],
            ]);
    }

    public function test_notifications_and_unread_count_shape(): void
    {
        $user = $this->createUser();

        $notification = Notifications::create([
            'user_id' => $user->id,
            'title' => 'Test notification',
            'description' => 'Body text',
        ]);

        $list = $this
            ->actingAs($user, 'sanctum')
            ->getJson('/api/notifications');

        $count = $this
            ->actingAs($user, 'sanctum')
            ->getJson('/api/notifications/unread-count');

        $list
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                  'notifications' => [
                    [
                      'id',
                      'title',
                      'description',
                      'created_at',
                    ],
                  ],
                ],
            ]);

        $count
            ->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'count',
                    'unread_count',
                ],
            ]);
    }
}

