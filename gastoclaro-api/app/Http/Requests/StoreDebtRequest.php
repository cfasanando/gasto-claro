<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreDebtRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'debt_type' => ['required', 'string', 'in:credit_card,bank_loan,third_party_loan,store_credit,recurring_commitment'],
            'name' => ['required', 'string', 'max:150'],
            'creditor_name' => ['nullable', 'string', 'max:150'],
            'currency' => ['required', 'string', 'max:10'],
            'original_amount' => ['nullable', 'numeric', 'min:0'],
            'current_balance' => ['required', 'numeric', 'min:0'],
            'monthly_due_amount' => ['nullable', 'numeric', 'min:0'],
            'minimum_payment' => ['nullable', 'numeric', 'min:0'],
            'interest_rate_monthly' => ['nullable', 'numeric', 'min:0'],
            'due_day' => ['nullable', 'integer', 'between:1,31'],
            'status' => ['nullable', 'in:active,paid,suspended,cancelled'],
            'has_fixed_payment' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
