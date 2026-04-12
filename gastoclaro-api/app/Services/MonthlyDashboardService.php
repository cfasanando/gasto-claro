<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Debt;
use App\Models\FixedExpense;
use App\Models\IncomeEvent;
use App\Models\User;
use Carbon\Carbon;

class MonthlyDashboardService
{
    public function build(User $user, int $year, int $month): array
    {
        $selectedMonth = Carbon::create($year, $month, 1)->startOfMonth();
        $startDate = $selectedMonth->copy()->startOfMonth();
        $endDate = $selectedMonth->copy()->endOfMonth();
        $today = now();

        $incomeEvents = $user->incomeEvents()
            ->with('incomeSource:id,name,type')
            ->whereBetween('expected_date', [
                $startDate->toDateString(),
                $endDate->toDateString(),
            ])
            ->orderBy('expected_date')
            ->orderBy('title')
            ->get();

        $fixedExpenses = $user->fixedExpenses()
            ->where('is_active', true)
            ->where('frequency', 'monthly')
            ->orderBy('due_day')
            ->orderBy('name')
            ->get();

        $debts = $user->debts()
            ->where('status', 'active')
            ->orderBy('due_day')
            ->orderBy('name')
            ->get();

        $expectedIncomeTotal = round(
            $incomeEvents->sum(fn (IncomeEvent $event): float => (float) $event->amount),
            2
        );

        $receivedIncomeTotal = round(
            $incomeEvents
                ->filter(function (IncomeEvent $event) use ($startDate, $endDate): bool {
                    if ($event->status !== 'received') {
                        return false;
                    }

                    $effectiveDate = $event->received_date ?? $event->expected_date;

                    if (!$effectiveDate) {
                        return false;
                    }

                    $date = $effectiveDate instanceof Carbon
                        ? $effectiveDate
                        : Carbon::parse((string) $effectiveDate);

                    return $date->betweenIncluded($startDate, $endDate);
                })
                ->sum(fn (IncomeEvent $event): float => (float) $event->amount),
            2
        );

        $fixedExpenseTotal = round(
            $fixedExpenses->sum(fn (FixedExpense $expense): float => (float) $expense->amount),
            2
        );

        $debtDueTotal = round(
            $debts->sum(fn (Debt $debt): float => $this->resolveDebtDueAmount($debt)),
            2
        );

        $obligationItems = collect();

        foreach ($fixedExpenses as $expense) {
            $dueDate = $this->buildDueDate($year, $month, $expense->due_day);

            $obligationItems->push([
                'source_type' => 'fixed_expense',
                'source_id' => $expense->id,
                'title' => $expense->name,
                'amount' => (float) $expense->amount,
                'currency' => $expense->currency,
                'due_day' => $expense->due_day,
                'due_date' => $dueDate?->toDateString(),
                'schedule_status' => $this->buildScheduleStatus($selectedMonth, $today, $expense->due_day),
            ]);
        }

        foreach ($debts as $debt) {
            $amountDue = $this->resolveDebtDueAmount($debt);

            if ($amountDue <= 0) {
                continue;
            }

            $dueDate = $this->buildDueDate($year, $month, $debt->due_day);

            $obligationItems->push([
                'source_type' => 'debt',
                'source_id' => $debt->id,
                'title' => $debt->name,
                'amount' => $amountDue,
                'currency' => $debt->currency,
                'due_day' => $debt->due_day,
                'due_date' => $dueDate?->toDateString(),
                'schedule_status' => $this->buildScheduleStatus($selectedMonth, $today, $debt->due_day),
            ]);
        }

        $obligationItems = $obligationItems
            ->sortBy([
                ['due_day', 'asc'],
                ['title', 'asc'],
            ])
            ->values();

        $upcomingItems = $obligationItems
            ->filter(fn (array $item): bool => in_array($item['schedule_status'], ['scheduled', 'due_soon'], true))
            ->values();

        $attentionItems = $obligationItems
            ->filter(fn (array $item): bool => $item['schedule_status'] === 'attention')
            ->values();

        $obligationTotal = round($fixedExpenseTotal + $debtDueTotal, 2);
        $projectedBalance = round($expectedIncomeTotal - $obligationTotal, 2);

        return [
            'selected_month' => $selectedMonth->format('Y-m'),
            'expected_income_total' => $expectedIncomeTotal,
            'received_income_total' => $receivedIncomeTotal,
            'fixed_expense_total' => $fixedExpenseTotal,
            'debt_due_total' => $debtDueTotal,
            'obligation_total' => $obligationTotal,
            'projected_balance' => $projectedBalance,
            'fixed_expenses_count' => $fixedExpenses->count(),
            'debts_count' => $debts->count(),
            'income_events_count' => $incomeEvents->count(),
            'upcoming_items' => $upcomingItems,
            'attention_items' => $attentionItems,
            'dashboard_note' => 'Schedule-based alerts only. Payment confirmation will be added with payment records.',
        ];
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

    private function buildDueDate(int $year, int $month, ?int $dueDay): ?Carbon
    {
        if ($dueDay === null) {
            return null;
        }

        $lastDayOfMonth = Carbon::create($year, $month, 1)->endOfMonth()->day;
        $safeDay = min($dueDay, $lastDayOfMonth);

        return Carbon::create($year, $month, $safeDay)->startOfDay();
    }

    private function buildScheduleStatus(Carbon $selectedMonth, Carbon $today, ?int $dueDay): string
    {
        if ($dueDay === null) {
            return 'no_due_day';
        }

        $isCurrentMonth = $selectedMonth->year === $today->year
            && $selectedMonth->month === $today->month;

        if (!$isCurrentMonth) {
            return 'scheduled';
        }

        if ($dueDay < $today->day) {
            return 'attention';
        }

        if ($dueDay <= ($today->day + 7)) {
            return 'due_soon';
        }

        return 'scheduled';
    }
}
