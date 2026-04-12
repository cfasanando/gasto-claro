<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePaymentObligationRequest;
use App\Http\Requests\UpdatePaymentObligationRequest;
use App\Models\PaymentObligation;
use App\Services\SyncMonthlyObligationsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentObligationController extends Controller
{
    public function __construct(
        private readonly SyncMonthlyObligationsService $syncMonthlyObligationsService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->paymentObligations()
            ->orderBy('due_date')
            ->orderBy('title');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }

        if ($request->filled('month')) {
            $query->whereMonth('due_date', (int) $request->input('month'));
        }

        if ($request->filled('year')) {
            $query->whereYear('due_date', (int) $request->input('year'));
        }

        return response()->json($query->get());
    }

    public function store(StorePaymentObligationRequest $request): JsonResponse
    {
        $obligation = $request->user()->paymentObligations()->create([
            ...$request->validated(),
            'status' => $request->input('status', 'pending'),
            'priority' => $request->input('priority', 'medium'),
        ]);

        return response()->json([
            'message' => 'Payment obligation created successfully.',
            'data' => $obligation,
        ], 201);
    }

    public function show(Request $request, PaymentObligation $paymentObligation): JsonResponse
    {
        $this->ensureOwnership($request, $paymentObligation);

        return response()->json($paymentObligation);
    }

    public function update(
        UpdatePaymentObligationRequest $request,
        PaymentObligation $paymentObligation,
    ): JsonResponse {
        $this->ensureOwnership($request, $paymentObligation);

        $paymentObligation->update([
            ...$request->validated(),
            'status' => $request->input('status', 'pending'),
            'priority' => $request->input('priority', 'medium'),
        ]);

        return response()->json([
            'message' => 'Payment obligation updated successfully.',
            'data' => $paymentObligation->fresh(),
        ]);
    }

    public function destroy(Request $request, PaymentObligation $paymentObligation): JsonResponse
    {
        $this->ensureOwnership($request, $paymentObligation);

        $paymentObligation->delete();

        return response()->json([
            'message' => 'Payment obligation deleted successfully.',
        ]);
    }

    public function syncMonthly(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'year' => ['nullable', 'integer', 'min:2000', 'max:2100'],
            'month' => ['nullable', 'integer', 'between:1,12'],
        ]);

        $year = (int) ($validated['year'] ?? now()->year);
        $month = (int) ($validated['month'] ?? now()->month);

        return response()->json([
            'message' => 'Monthly obligations synced successfully.',
            'data' => $this->syncMonthlyObligationsService->sync(
                $request->user(),
                $year,
                $month
            ),
        ]);
    }

    private function ensureOwnership(Request $request, PaymentObligation $paymentObligation): void
    {
        abort_unless(
            (int) $request->user()->id === (int) $paymentObligation->user_id,
            403,
            'Unauthorized.'
        );
    }
}
