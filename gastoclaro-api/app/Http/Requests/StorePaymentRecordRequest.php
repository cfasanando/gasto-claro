<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePaymentRecordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'payment_obligation_id' => [
                'required',
                'integer',
                Rule::exists('payment_obligations', 'id')->where(
                    fn ($query) => $query->where('user_id', $this->user()->id)
                ),
            ],
            'paid_amount' => ['required', 'numeric', 'min:0.01'],
            'currency' => ['required', 'string', 'max:10'],
            'paid_at' => ['required', 'date'],
            'payment_method' => [
                'required',
                'in:cash,bank_transfer,credit_card,debit_card,yape,plin,other',
            ],
            'note' => ['nullable', 'string'],
        ];
    }
}
