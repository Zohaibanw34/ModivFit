<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subscriptions;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    public function select(Request $request)
    {
        $user = $request->user();

        $plan = $request->input('plan') ?? $request->input('plan_name') ?? $request->input('name');
        $tier = $request->input('tier') ?? $request->input('plan_type') ?? $request->input('subscription_type');

        $plan = is_string($plan) ? strtolower(trim($plan)) : null;
        $tier = is_string($tier) ? strtolower(trim($tier)) : null;

        $sub = Subscriptions::updateOrCreate(
            ['user_id' => $user->id],
            [
                'duration' => $tier ?: 'basic',
                'date' => now()->toDateString(),
                'status' => 'active',
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Subscription updated',
            'data' => [
                'status' => $sub->status,
            ],
        ]);
    }

    public function get(Request $request)
    {
        $user = $request->user();
        $sub = Subscriptions::firstOrCreate(['user_id' => $user->id], ['status' => 'inactive']);

        return response()->json([
            'success' => true,
            'message' => 'Subscription fetched',
            'data' => [
                'status' => $sub->status,
                'duration' => $sub->duration,
            ],
        ]);
    }

    public function plans()
    {
        return response()->json([
            'message' => 'Plans fetched',
            'data' => [
                'plans' => [
                    ['name' => 'monthly', 'tier' => 'basic', 'price' => 0],
                    ['name' => 'monthly', 'tier' => 'premium', 'price' => 9.99],
                    ['name' => 'yearly', 'tier' => 'premium', 'price' => 99.99],
                ],
            ],
        ]);
    }

    public function checkout(Request $request)
    {
        // Placeholder: integrate payment provider later.
        return response()->json([
            'message' => 'Checkout initiated',
            'data' => [
                'checkout_url' => null,
                'status' => 'pending',
            ],
        ]);
    }
}

