<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Debt extends Model
{
    protected $fillable = [
        'user_id',
        'debt_type',
        'name',
        'creditor_name',
        'currency',
        'original_amount',
        'current_balance',
        'monthly_due_amount',
        'minimum_payment',
        'interest_rate_monthly',
        'due_day',
        'status',
        'has_fixed_payment',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'original_amount' => 'decimal:2',
            'current_balance' => 'decimal:2',
            'monthly_due_amount' => 'decimal:2',
            'minimum_payment' => 'decimal:2',
            'interest_rate_monthly' => 'decimal:2',
            'has_fixed_payment' => 'boolean',
            'due_day' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
