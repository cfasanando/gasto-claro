<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        Schema::create('debts', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->string('debt_type', 50);
            $table->string('name', 150);
            $table->string('creditor_name', 150)->nullable();

            $table->string('currency', 10)->default('PEN');

            $table->decimal('original_amount', 12, 2)->nullable();
            $table->decimal('current_balance', 12, 2)->default(0);
            $table->decimal('monthly_due_amount', 12, 2)->nullable();
            $table->decimal('minimum_payment', 12, 2)->nullable();
            $table->decimal('interest_rate_monthly', 8, 2)->nullable();

            $table->unsignedTinyInteger('due_day')->nullable();

            $table->string('status', 20)->default('active');
            $table->boolean('has_fixed_payment')->default(false);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'debt_type']);
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'due_day']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('debts');
    }
};
