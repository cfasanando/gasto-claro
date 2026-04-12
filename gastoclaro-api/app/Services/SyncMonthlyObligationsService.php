<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Debt;
use App\Models\FixedExpense;
use App\Models\PaymentObligation;
use App\Models\User;
use Carbon\Carbon;

class SyncMonthlyObligationsService
{
    public function sync(User $user, int $year, int $month): array
    {
        $createdCount = 0;
        $updatedCount = 0;

        $fixedExpenses = $user->fixedExpenses()
            ->where('is_active', true)
            ->where('frequency', 'monthly')
            ->get();

        foreach ($fixedExpenses as $expense) {
            if ($expense->due_day === null) {
                continue;
            }

            $dueDate = $this->buildDueDate($year, $month, $expense->due_day);

            [$obligation, $created] = $this->updateOrCreateObligation(
                userId: (int) $user->id,
                sourceType: 'fixed_expense',
                sourceId: (int) $expense->id,
                dueDate: $dueDate,
                values: [
                    'title' => $expense->name,
                    'obligation_type' => 'fixed_expense',
                    'amount_due' => $expense->amount,
                    'currency' => $expense->currency,
                    'status' => $this->resolveInitialStatus($dueDate),
                    'priority' => $expense->is_mandatory ? 'high' : 'medium',
                    'notes' => $expense->notes,
                ],
            );

            if ($created) {
                $createdCount++;
            } elseif ($obligation->wasChanged()) {
                $updatedCount++;
            }
        }

        $debts = $user->debts()
            ->where('status', 'active')
            ->get();

        foreach ($debts as $debt) {
            if ($debt->due_day === null) {
                continue;
            }

            $amountDue = $this->resolveDebtDueAmount($debt);

            if ($amountDue <= 0) {
                continue;
            }

            $dueDate = $this->buildDueDate($year, $month, $debt->due_day);

            [$obligation, $created] = $this->updateOrCreateObligation(
                userId: (int) $user->id,
                sourceType: 'debt',
                sourceId: (int) $debt->id,
                dueDate: $dueDate,
                values: [
                    'title' => $debt->name,
                    'obligation_type' => $debt->monthly_due_amount !== null
                        ? 'monthly_installment'
                        : 'minimum_payment',
                    'amount_due' => $amountDue,
                    'currency' => $debt->currency,
                    'status' => $this->resolveInitialStatus($dueDate),
                    'priority' => 'high',
                    'notes' => $debt->notes,
                ],
            );

            if ($created) {
                $createdCount++;
            } elseif ($obligation->wasChanged()) {
                $updatedCount++;
            }
        }

        return [
            'year' => $year,
            'month' => $month,
            'created_count' => $createdCount,
            'updated_count' => $updatedCount,
        ];
    }

    private function updateOrCreateObligation(
        int $userId,
        string $sourceType,
        int $sourceId,
        Carbon $dueDate,
        array $values,
    ): array {
        $obligation = PaymentObligation::query()->updateOrCreate(
            [
                'user_id' => $userId,
                'source_type' => $sourceType,
                'source_id' => $sourceId,
                'due_date' => $dueDate->toDateString(),
            ],
            $values
        );

        return [$obligation, $obligation->wasRecentlyCreated];
    }

    private function buildDueDate(int $year, int $month, int $dueDay): Carbon
    {
        $lastDayOfMonth = Carbon::create($year, $month, 1)->endOfMonth()->day;
        $safeDay = min($dueDay, $lastDayOfMonth);

        return Carbon::create($year, $month, $safeDay)->startOfDay();
    }

    private function resolveDebtDueAmount(Debt $debt): float
    {
        if ($debt->monthly_due_amount !== null) {
            return (float) $debt->monthly_due_amount;
        }

        if ($debt->minimum_payment !== null) {
            return (float) $debt->minimum_payment;
        }

        return 0.0;
    }

    private function resolveInitialStatus(Carbon $dueDate): string
    {
        return $dueDate->isPast() ? 'overdue' : 'pending';
    }
}
