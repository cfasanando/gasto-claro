<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreIncomeSourceRequest;
use App\Http\Requests\UpdateIncomeSourceRequest;
use App\Models\IncomeSource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class IncomeSourceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->incomeSources()
            ->orderBy('type')
            ->orderBy('name');

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        if ($request->filled('type')) {
            $query->where('type', $request->string('type')->toString());
        }

        return response()->json($query->get());
    }

    public function store(StoreIncomeSourceRequest $request): JsonResponse
    {
        $incomeSource = $request->user()->incomeSources()->create([
            ...$request->validated(),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return response()->json([
            'message' => 'Income source created successfully.',
            'data' => $incomeSource,
        ], 201);
    }

    public function show(Request $request, IncomeSource $incomeSource): JsonResponse
    {
        $this->ensureOwnership($request, $incomeSource);

        return response()->json($incomeSource);
    }

    public function update(UpdateIncomeSourceRequest $request, IncomeSource $incomeSource): JsonResponse
    {
        $this->ensureOwnership($request, $incomeSource);

        $incomeSource->update([
            ...$request->validated(),
            'is_active' => $request->boolean('is_active', true),
        ]);

        return response()->json([
            'message' => 'Income source updated successfully.',
            'data' => $incomeSource->fresh(),
        ]);
    }

    public function destroy(Request $request, IncomeSource $incomeSource): JsonResponse
    {
        $this->ensureOwnership($request, $incomeSource);

        $incomeSource->delete();

        return response()->json([
            'message' => 'Income source deleted successfully.',
        ]);
    }

    private function ensureOwnership(Request $request, IncomeSource $incomeSource): void
    {
        abort_unless(
            (int) $request->user()->id === (int) $incomeSource->user_id,
            403,
            'Unauthorized.'
        );
    }
}
