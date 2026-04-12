<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentObligation extends Model
{
    protected $fillable = [
        'user_id',
        'source_type',
        'source_id',
        'title',
        'obligation_type',
        'amount_due',
        'currency',
        'due_date',
        'status',
        'priority',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'amount_due' => 'decimal:2',
            'due_date' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
