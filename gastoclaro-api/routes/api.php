<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DebtController;
use App\Http\Controllers\Api\FixedExpenseController;
use Illuminate\Support\Facades\Route;

Route::get('/ping', function () {
    return response()->json([
        'message' => 'API is working.',
        'app' => 'GastoClaro API',
    ]);
});

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::apiResource('fixed-expenses', FixedExpenseController::class);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::apiResource('debts', DebtController::class);
    Route::apiResource('fixed-expenses', FixedExpenseController::class);
});

