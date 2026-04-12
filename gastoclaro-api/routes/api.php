<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DebtController;
use App\Http\Controllers\Api\FixedExpenseController;
use App\Http\Controllers\Api\IncomeEventController;
use App\Http\Controllers\Api\IncomeSourceController;
use App\Http\Controllers\Api\PaymentObligationController;
use App\Http\Controllers\Api\PaymentRecordController;
use App\Http\Controllers\Api\SyncMonthlyObligationsController;
use Illuminate\Support\Facades\Route;

Route::get('/ping', function () {
    return response()->json([
        'message' => 'API is working.',
        'app' => 'GastoClaro API',
    ]);
});

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/dashboard/monthly', [DashboardController::class, 'monthly']);

    Route::post('/sync-monthly-obligations', SyncMonthlyObligationsController::class);

    Route::apiResource('payment-obligations', PaymentObligationController::class)
        ->whereNumber('payment_obligation');

    Route::get('/payment-records', [PaymentRecordController::class, 'index']);
    Route::post('/payment-records', [PaymentRecordController::class, 'store']);
    Route::get('/payment-records/{paymentRecord}', [PaymentRecordController::class, 'show']);
    Route::delete('/payment-records/{paymentRecord}', [PaymentRecordController::class, 'destroy']);

    Route::apiResource('debts', DebtController::class)->whereNumber('debt');
    Route::apiResource('fixed-expenses', FixedExpenseController::class)->whereNumber('fixed_expense');
    Route::apiResource('income-sources', IncomeSourceController::class)->whereNumber('income_source');
    Route::apiResource('income-events', IncomeEventController::class)->whereNumber('income_event');
});
