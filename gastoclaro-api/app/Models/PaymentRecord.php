<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentRecord extends Model
{
    protected $fillable = [
        'user_id',
        'payment_obligation_id',
        'paid_amount',
        'currency',
        'paid_at',
        'payment_method',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'paid_amount' => 'decimal:2',
            'paid_at' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function paymentObligation(): BelongsTo
    {
        return $this->belongsTo(PaymentObligation::class);
    }
}
