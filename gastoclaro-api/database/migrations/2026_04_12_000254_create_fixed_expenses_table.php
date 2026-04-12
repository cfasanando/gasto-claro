<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        Schema::create('fixed_expenses', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->string('name', 150);
            $table->string('category', 80)->nullable();
            $table->decimal('amount', 12, 2);
            $table->string('currency', 10)->default('PEN');

            $table->unsignedTinyInteger('due_day')->nullable();
            $table->string('frequency', 20)->default('monthly');

            $table->boolean('is_mandatory')->default(true);
            $table->boolean('is_active')->default(true);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'is_active']);
            $table->index(['user_id', 'due_day']);
            $table->index(['user_id', 'frequency']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixed_expenses');
    }
};
