<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFixedExpenseRequest;
use App\Http\Requests\UpdateFixedExpenseRequest;
use App\Models\FixedExpense;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FixedExpenseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->fixedExpenses()
            ->orderBy('due_day')
            ->orderBy('name');

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        if ($request->filled('frequency')) {
            $query->where('frequency', $request->string('frequency')->toString());
        }

        return response()->json($query->get());
    }

    public function store(StoreFixedExpenseRequest $request): JsonResponse
    {
        $fixedExpense = $request->user()->fixedExpenses()->create([
            ...$request->validated(),
            'is_mandatory' => $request->boolean('is_mandatory', true),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return response()->json([
            'message' => 'Fixed expense created successfully.',
            'data' => $fixedExpense,
        ], 201);
    }

    public function show(Request $request, FixedExpense $fixedExpense): JsonResponse
    {
        $this->ensureOwnership($request, $fixedExpense);

        return response()->json($fixedExpense);
    }

    public function update(UpdateFixedExpenseRequest $request, FixedExpense $fixedExpense): JsonResponse
    {
        $this->ensureOwnership($request, $fixedExpense);

        $fixedExpense->update([
            ...$request->validated(),
            'is_mandatory' => $request->boolean('is_mandatory', true),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return response()->json([
            'message' => 'Fixed expense updated successfully.',
            'data' => $fixedExpense->fresh(),
        ]);
    }

    public function destroy(Request $request, FixedExpense $fixedExpense): JsonResponse
    {
        $this->ensureOwnership($request, $fixedExpense);

        $fixedExpense->delete();

        return response()->json([
            'message' => 'Fixed expense deleted successfully.',
        ]);
    }

    private function ensureOwnership(Request $request, FixedExpense $fixedExpense): void
    {
        abort_unless(
            (int) $request->user()->id === (int) $fixedExpense->user_id,
            403,
            'Unauthorized.'
        );
    }
}
