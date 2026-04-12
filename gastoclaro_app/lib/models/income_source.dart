class IncomeSource {
  final int id;
  final String name;
  final String type;
  final double? defaultAmount;
  final String currency;
  final bool isActive;
  final String? notes;

  IncomeSource({
    required this.id,
    required this.name,
    required this.type,
    required this.defaultAmount,
    required this.currency,
    required this.isActive,
    required this.notes,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    double? toNullableDouble(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value.toDouble();
      }

      if (value is double) {
        return value;
      }

      return double.tryParse(value.toString());
    }

    int toInt(dynamic value) {
      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString()) ?? 0;
    }

    return IncomeSource(
      id: toInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      defaultAmount: toNullableDouble(json['default_amount']),
      currency: json['currency']?.toString() ?? 'PEN',
      isActive: json['is_active'] == true,
      notes: json['notes']?.toString(),
    );
  }
}