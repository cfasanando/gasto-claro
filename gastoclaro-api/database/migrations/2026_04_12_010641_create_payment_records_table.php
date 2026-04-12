<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        Schema::create('payment_records', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('payment_obligation_id')->constrained()->cascadeOnDelete();

            $table->decimal('paid_amount', 12, 2);
            $table->string('currency', 10)->default('PEN');
            $table->date('paid_at');
            $table->string('payment_method', 30)->default('other');
            $table->text('note')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'paid_at']);
            $table->index(['user_id', 'payment_obligation_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_records');
    }
};
