class PaymentObligation {
  final int id;
  final String? sourceType;
  final int? sourceId;
  final String title;
  final String obligationType;
  final double amountDue;
  final String currency;
  final DateTime? dueDate;
  final String status;
  final String priority;
  final String? notes;

  PaymentObligation({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.obligationType,
    required this.amountDue,
    required this.currency,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.notes,
  });

  factory PaymentObligation.fromJson(Map<String, dynamic> json) {
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

    DateTime? toNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }

      return DateTime.tryParse(value.toString());
    }

    return PaymentObligation(
      id: toNullableInt(json['id']) ?? 0,
      sourceType: json['source_type']?.toString(),
      sourceId: toNullableInt(json['source_id']),
      title: json['title']?.toString() ?? '',
      obligationType: json['obligation_type']?.toString() ?? '',
      amountDue: toDouble(json['amount_due']),
      currency: json['currency']?.toString() ?? 'PEN',
      dueDate: toNullableDate(json['due_date']),
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority']?.toString() ?? 'medium',
      notes: json['notes']?.toString(),
    );
  }
}