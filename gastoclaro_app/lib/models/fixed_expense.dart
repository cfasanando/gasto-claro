class FixedExpense {
  final int id;
  final String name;
  final String? category;
  final double amount;
  final String currency;
  final int? dueDay;
  final String frequency;
  final bool isMandatory;
  final bool isActive;
  final String? notes;

  FixedExpense({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.currency,
    required this.dueDay,
    required this.frequency,
    required this.isMandatory,
    required this.isActive,
    required this.notes,
  });

  factory FixedExpense.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is int) {
        return value.toDouble();
      }

      if (value is double) {
        return value;
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    int? toNullableInt(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    return FixedExpense(
      id: toNullableInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      amount: toDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'PEN',
      dueDay: toNullableInt(json['due_day']),
      frequency: json['frequency']?.toString() ?? 'monthly',
      isMandatory: json['is_mandatory'] == true,
      isActive: json['is_active'] == true,
      notes: json['notes']?.toString(),
    );
  }
}