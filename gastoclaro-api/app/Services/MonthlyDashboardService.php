<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\IncomeEvent;
use App\Models\PaymentObligation;
use App\Models\PaymentRecord;
use App\Models\User;
use Carbon\Carbon;

class MonthlyDashboardService
{
    public function build(User $user, int $year, int $month): array
    {
        $selectedMonth = Carbon::create($year, $month, 1)->startOfMonth();
        $startDate = $selectedMonth->copy()->startOfMonth();
        $endDate = $selectedMonth->copy()->endOfMonth();
        $today = now()->startOfDay();

        $incomeEvents = $user->incomeEvents()
            ->with('incomeSource:id,name,type')
            ->whereBetween('expected_date', [
                $startDate->toDateString(),
                $endDate->toDateString(),
            ])
            ->orderBy('expected_date')
            ->orderBy('title')
            ->get();

        $paymentObligations = $user->paymentObligations()
            ->whereBetween('due_date', [
                $startDate->toDateString(),
                $endDate->toDateString(),
            ])
            ->orderBy('due_date')
            ->orderBy('title')
            ->get();

        $paymentRecords = $user->paymentRecords()
            ->with('paymentObligation:id,title,due_date,status')
            ->whereBetween('paid_at', [
                $startDate->toDateString(),
                $endDate->toDateString(),
            ])
            ->orderByDesc('paid_at')
            ->orderByDesc('id')
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

        $obligationTotal = round(
            $paymentObligations->sum(fn (PaymentObligation $obligation): float => (float) $obligation->amount_due),
            2
        );

        $paidTotal = round(
            $paymentRecords->sum(fn (PaymentRecord $record): float => (float) $record->paid_amount),
            2
        );

        $remainingObligationTotal = round(max(0, $obligationTotal - $paidTotal), 2);
        $projectedBalance = round($expectedIncomeTotal - $obligationTotal, 2);
        $actualBalance = round($receivedIncomeTotal - $paidTotal, 2);

        $upcomingItems = $paymentObligations
            ->filter(function (PaymentObligation $obligation) use ($selectedMonth, $today): bool {
                if (in_array($obligation->status, ['paid', 'cancelled'], true)) {
                    return false;
                }

                $isCurrentMonth = $selectedMonth->year === $today->year
                    && $selectedMonth->month === $today->month;

                if (!$isCurrentMonth) {
                    return true;
                }

                return $obligation->due_date->greaterThanOrEqualTo($today);
            })
            ->map(fn (PaymentObligation $obligation): array => $this->mapObligation($obligation))
            ->values();

        $attentionItems = $paymentObligations
            ->filter(function (PaymentObligation $obligation) use ($selectedMonth, $today): bool {
                if (in_array($obligation->status, ['paid', 'cancelled'], true)) {
                    return false;
                }

                if (in_array($obligation->status, ['overdue', 'partial'], true)) {
                    return true;
                }

                $isCurrentMonth = $selectedMonth->year === $today->year
                    && $selectedMonth->month === $today->month;

                if (!$isCurrentMonth) {
                    return false;
                }

                return $obligation->due_date->lessThan($today);
            })
            ->map(fn (PaymentObligation $obligation): array => $this->mapObligation($obligation))
            ->values();

        $paidItems = $paymentObligations
            ->where('status', 'paid')
            ->map(fn (PaymentObligation $obligation): array => $this->mapObligation($obligation))
            ->values();

        $pendingItems = $paymentObligations
            ->filter(fn (PaymentObligation $obligation): bool => in_array($obligation->status, ['pending', 'partial', 'overdue'], true))
            ->map(fn (PaymentObligation $obligation): array => $this->mapObligation($obligation))
            ->values();

        return [
            'selected_month' => $selectedMonth->format('Y-m'),
            'expected_income_total' => $expectedIncomeTotal,
            'received_income_total' => $receivedIncomeTotal,
            'obligation_total' => $obligationTotal,
            'paid_total' => $paidTotal,
            'remaining_obligation_total' => $remainingObligationTotal,
            'projected_balance' => $projectedBalance,
            'actual_balance' => $actualBalance,
            'payment_obligations_count' => $paymentObligations->count(),
            'payment_records_count' => $paymentRecords->count(),
            'income_events_count' => $incomeEvents->count(),
            'upcoming_items' => $upcomingItems,
            'attention_items' => $attentionItems,
            'paid_items' => $paidItems,
            'pending_items' => $pendingItems,
            'dashboard_note' => 'Monthly dashboard now reflects obligations and recorded payments.',
        ];
    }

    private function mapObligation(PaymentObligation $obligation): array
    {
        return [
            'id' => $obligation->id,
            'source_type' => $obligation->source_type,
            'source_id' => $obligation->source_id,
            'title' => $obligation->title,
            'obligation_type' => $obligation->obligation_type,
            'amount_due' => (float) $obligation->amount_due,
            'currency' => $obligation->currency,
            'due_date' => $obligation->due_date?->toDateString(),
            'status' => $obligation->status,
            'priority' => $obligation->priority,
            'notes' => $obligation->notes,
        ];
    }
}
