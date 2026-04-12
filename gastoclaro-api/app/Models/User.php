<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Models\FixedExpense;
use App\Models\IncomeSource;
use App\Models\IncomeEvent;
use App\Models\PaymentObligation;
use App\Models\PaymentRecord;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function debts(): HasMany
    {
        return $this->hasMany(Debt::class);
    }

    public function fixedExpenses(): HasMany
    {
        return $this->hasMany(FixedExpense::class);
    }

    public function incomeSources(): HasMany
    {
        return $this->hasMany(IncomeSource::class);
    }

    public function incomeEvents(): HasMany
    {
        return $this->hasMany(IncomeEvent::class);
    }

    public function paymentObligations(): HasMany
    {
        return $this->hasMany(PaymentObligation::class);
    }

    public function paymentRecords(): HasMany
    {
        return $this->hasMany(PaymentRecord::class);
    }
}
