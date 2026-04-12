<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDebtRequest;
use App\Http\Requests\UpdateDebtRequest;
use App\Models\Debt;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DebtController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->debts()
            ->orderBy('due_day')
            ->orderBy('name');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }

        if ($request->filled('debt_type')) {
            $query->where('debt_type', $request->string('debt_type')->toString());
        }

        return response()->json($query->get());
    }

    public function store(StoreDebtRequest $request): JsonResponse
    {
        $debt = $request->user()->debts()->create([
            ...$request->validated(),
            'status' => $request->input('status', 'active'),
            'has_fixed_payment' => $request->boolean('has_fixed_payment', false),
        ]);

        return response()->json([
            'message' => 'Debt created successfully.',
            'data' => $debt,
        ], 201);
    }

    public function show(Request $request, Debt $debt): JsonResponse
    {
        $this->ensureOwnership($request, $debt);

        return response()->json($debt);
    }

    public function update(UpdateDebtRequest $request, Debt $debt): JsonResponse
    {
        $this->ensureOwnership($request, $debt);

        $debt->update([
            ...$request->validated(),
            'has_fixed_payment' => $request->boolean('has_fixed_payment', false),
        ]);

        return response()->json([
            'message' => 'Debt updated successfully.',
            'data' => $debt->fresh(),
        ]);
    }

    public function destroy(Request $request, Debt $debt): JsonResponse
    {
        $this->ensureOwnership($request, $debt);

        $debt->delete();

        return response()->json([
            'message' => 'Debt deleted successfully.',
        ]);
    }

    private function ensureOwnership(Request $request, Debt $debt): void
    {
        abort_unless(
            (int) $request->user()->id === (int) $debt->user_id,
            403,
            'Unauthorized.'
        );
    }
}
