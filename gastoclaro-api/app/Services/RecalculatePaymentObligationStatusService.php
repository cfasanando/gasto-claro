<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\PaymentObligation;

class RecalculatePaymentObligationStatusService
{
    public function handle(PaymentObligation $paymentObligation): PaymentObligation
    {
        if ($paymentObligation->status === 'cancelled') {
            return $paymentObligation;
        }

        $totalPaid = (float) $paymentObligation->paymentRecords()->sum('paid_amount');
        $amountDue = (float) $paymentObligation->amount_due;

        if ($totalPaid >= $amountDue && $amountDue > 0) {
            $newStatus = 'paid';
        } elseif ($totalPaid > 0) {
            $newStatus = 'partial';
        } else {
            $newStatus = $paymentObligation->due_date->isPast() ? 'overdue' : 'pending';
        }

        $paymentObligation->update([
            'status' => $newStatus,
        ]);

        return $paymentObligation->fresh();
    }
}
