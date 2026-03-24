<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class LegacyController extends Controller
{
    public function health()
    {
        return response()->json([
            'ok' => true,
            'message' => 'OK',
        ]);
    }

    public function handle(Request $request)
    {
        $endpoint = (string) $request->route('endpoint');

        return response()->json([
            'message' => 'OK',
            'endpoint' => $endpoint,
            'data' => $request->all(),
        ]);
    }
}

