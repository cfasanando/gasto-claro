<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\SyncMonthlyObligationsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SyncMonthlyObligationsController extends Controller
{
    public function __construct(
        private readonly SyncMonthlyObligationsService $syncMonthlyObligationsService,
    ) {}

    public function __invoke(Request $request): JsonResponse
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
}
