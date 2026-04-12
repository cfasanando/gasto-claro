<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateIncomeEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'income_source_id' => [
                'nullable',
                'integer',
                Rule::exists('income_sources', 'id')->where(
                    fn ($query) => $query->where('user_id', $this->user()->id)
                ),
            ],
            'title' => ['required', 'string', 'max:150'],
            'amount' => ['required', 'numeric', 'min:0'],
            'currency' => ['required', 'string', 'max:10'],
            'expected_date' => ['required', 'date'],
            'received_date' => ['nullable', 'date'],
            'status' => ['nullable', 'in:planned,received,missed'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
