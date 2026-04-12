<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePaymentObligationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'source_type' => ['nullable', 'in:fixed_expense,debt,manual'],
            'source_id' => ['nullable', 'integer', 'min:1'],
            'title' => ['required', 'string', 'max:150'],
            'obligation_type' => [
                'required',
                'in:fixed_expense,minimum_payment,monthly_installment,interest_payment,manual_commitment',
            ],
            'amount_due' => ['required', 'numeric', 'min:0'],
            'currency' => ['required', 'string', 'max:10'],
            'due_date' => ['required', 'date'],
            'status' => ['nullable', 'in:pending,partial,paid,overdue,cancelled'],
            'priority' => ['nullable', 'in:low,medium,high,critical'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
