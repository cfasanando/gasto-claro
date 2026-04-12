<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FixedExpense extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'category',
        'amount',
        'currency',
        'due_day',
        'frequency',
        'is_mandatory',
        'is_active',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'due_day' => 'integer',
            'is_mandatory' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
