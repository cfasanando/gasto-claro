<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreIncomeEventRequest;
use App\Http\Requests\UpdateIncomeEventRequest;
use App\Models\IncomeEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class IncomeEventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->incomeEvents()
            ->with('incomeSource')
            ->orderBy('expected_date')
            ->orderBy('title');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }

        if ($request->filled('month')) {
            $query->whereMonth('expected_date', (int) $request->input('month'));
        }

        if ($request->filled('year')) {
            $query->whereYear('expected_date', (int) $request->input('year'));
        }

        return response()->json($query->get());
    }

    public function store(StoreIncomeEventRequest $request): JsonResponse
    {
        $incomeEvent = $request->user()->incomeEvents()->create([
            ...$request->validated(),
            'status' => $request->input('status', 'planned'),
        ]);

        return response()->json([
            'message' => 'Income event created successfully.',
            'data' => $incomeEvent->load('incomeSource'),
        ], 201);
    }

    public function show(Request $request, IncomeEvent $incomeEvent): JsonResponse
    {
        $this->ensureOwnership($request, $incomeEvent);

        return response()->json($incomeEvent->load('incomeSource'));
    }

    public function update(UpdateIncomeEventRequest $request, IncomeEvent $incomeEvent): JsonResponse
    {
        $this->ensureOwnership($request, $incomeEvent);

        $incomeEvent->update([
            ...$request->validated(),
            'status' => $request->input('status', 'planned'),
        ]);

        return response()->json([
            'message' => 'Income event updated successfully.',
            'data' => $incomeEvent->fresh()->load('incomeSource'),
        ]);
    }

    public function destroy(Request $request, IncomeEvent $incomeEvent): JsonResponse
    {
        $this->ensureOwnership($request, $incomeEvent);

        $incomeEvent->delete();

        return response()->json([
            'message' => 'Income event deleted successfully.',
        ]);
    }

    private function ensureOwnership(Request $request, IncomeEvent $incomeEvent): void
    {
        abort_unless(
            (int) $request->user()->id === (int) $incomeEvent->user_id,
            403,
            'Unauthorized.'
        );
    }
}
