<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        Schema::create('income_events', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('income_source_id')->nullable()->constrained()->nullOnDelete();

            $table->string('title', 150);
            $table->decimal('amount', 12, 2);
            $table->string('currency', 10)->default('PEN');

            $table->date('expected_date');
            $table->date('received_date')->nullable();

            $table->string('status', 20)->default('planned');
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'expected_date']);
            $table->index(['user_id', 'received_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('income_events');
    }
};
