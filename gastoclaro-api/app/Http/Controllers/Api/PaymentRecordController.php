<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePaymentRecordRequest;
use App\Models\PaymentObligation;
use App\Models\PaymentRecord;
use App\Services\RecalculatePaymentObligationStatusService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentRecordController extends Controller
{
    public function __construct(
        private readonly RecalculatePaymentObligationStatusService $recalculatePaymentObligationStatusService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->paymentRecords()
            ->with('paymentObligation')
            ->orderByDesc('paid_at')
            ->orderByDesc('id');

        if ($request->filled('payment_obligation_id')) {
            $query->where('payment_obligation_id', (int) $request->input('payment_obligation_id'));
        }

        if ($request->filled('month')) {
            $query->whereMonth('paid_at', (int) $request->input('month'));
        }

        if ($request->filled('year')) {
            $query->whereYear('paid_at', (int) $request->input('year'));
        }

        return response()->json($query->get());
    }

    public function store(StorePaymentRecordRequest $request): JsonResponse
    {
        $paymentRecord = $request->user()->paymentRecords()->create($request->validated());

        $paymentObligation = PaymentObligation::query()->findOrFail(
            (int) $request->input('payment_obligation_id')
        );

        $this->recalculatePaymentObligationStatusService->handle($paymentObligation);

        return response()->json([
            'message' => 'Payment record created successfully.',
            'data' => $paymentRecord->load('paymentObligation'),
        ], 201);
    }

    public function show(Request $request, PaymentRecord $paymentRecord): JsonResponse
    {
        $this->ensureOwnership($request, $paymentRecord);

        return response()->json($paymentRecord->load('paymentObligation'));
    }

    public function destroy(Request $request, PaymentRecord $paymentRecord): JsonResponse
    {
        $this->ensureOwnership($request, $paymentRecord);

        $paymentObligation = $paymentRecord->paymentObligation;

        $paymentRecord->delete();

        $this->recalculatePaymentObligationStatusService->handle($paymentObligation);

        return response()->json([
            'message' => 'Payment record deleted successfully.',
        ]);
    }

    private function ensureOwnership(Request $request, PaymentRecord $paymentRecord): void
    {
        abort_unless(
            (int) $request->user()->id === (int) $paymentRecord->user_id,
            403,
            'Unauthorized.'
        );
    }
}
