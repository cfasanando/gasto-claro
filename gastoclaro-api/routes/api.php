<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DebtController;
use App\Http\Controllers\Api\FixedExpenseController;
use App\Http\Controllers\Api\IncomeSourceController;
use App\Http\Controllers\Api\IncomeEventController;
use App\Http\Controllers\Api\DashboardController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\PaymentObligationController;
use App\Http\Controllers\Api\PaymentRecordController;

Route::get('/ping', function () {
    return response()->json([
        'message' => 'API is working.',
        'app' => 'GastoClaro API',
    ]);
});

Route::get('/dashboard/monthly', [DashboardController::class, 'monthly']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::apiResource('fixed-expenses', FixedExpenseController::class);
Route::apiResource('income-sources', IncomeSourceController::class);
Route::apiResource('income-events', IncomeEventController::class);
Route::post('/payment-obligations/sync-monthly', [PaymentObligationController::class, 'syncMonthly']);
Route::apiResource('payment-obligations', PaymentObligationController::class);
Route::get('/payment-records', [PaymentRecordController::class, 'index']);
Route::post('/payment-records', [PaymentRecordController::class, 'store']);
Route::get('/payment-records/{paymentRecord}', [PaymentRecordController::class, 'show']);
Route::delete('/payment-records/{paymentRecord}', [PaymentRecordController::class, 'destroy']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/dashboard/monthly', [DashboardController::class, 'monthly']);

    Route::post('/payment-obligations/sync-monthly', [PaymentObligationController::class, 'syncMonthly']);
    Route::apiResource('payment-obligations', PaymentObligationController::class);

    Route::get('/payment-records', [PaymentRecordController::class, 'index']);
    Route::post('/payment-records', [PaymentRecordController::class, 'store']);
    Route::get('/payment-records/{paymentRecord}', [PaymentRecordController::class, 'show']);
    Route::delete('/payment-records/{paymentRecord}', [PaymentRecordController::class, 'destroy']);

    Route::apiResource('debts', DebtController::class);
    Route::apiResource('fixed-expenses', FixedExpenseController::class);
    Route::apiResource('income-sources', IncomeSourceController::class);
    Route::apiResource('income-events', IncomeEventController::class);
});
