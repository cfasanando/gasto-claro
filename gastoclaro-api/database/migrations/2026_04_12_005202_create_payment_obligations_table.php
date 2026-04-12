<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        Schema::create('payment_obligations', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->string('source_type', 30)->nullable();
            $table->unsignedBigInteger('source_id')->nullable();

            $table->string('title', 150);
            $table->string('obligation_type', 50);

            $table->decimal('amount_due', 12, 2);
            $table->string('currency', 10)->default('PEN');

            $table->date('due_date');
            $table->string('status', 20)->default('pending');
            $table->string('priority', 20)->default('medium');

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'due_date']);
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'source_type', 'source_id']);
            $table->unique(
                ['user_id', 'source_type', 'source_id', 'due_date'],
                'payment_obligations_unique_source_due_date'
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_obligations');
    }
};
