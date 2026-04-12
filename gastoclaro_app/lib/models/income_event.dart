class IncomeEvent {
  final int id;
  final int? incomeSourceId;
  final String title;
  final double amount;
  final String currency;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final String status;
  final String? notes;
  final String? incomeSourceName;

  IncomeEvent({
    required this.id,
    required this.incomeSourceId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.expectedDate,
    required this.receivedDate,
    required this.status,
    required this.notes,
    required this.incomeSourceName,
  });

  factory IncomeEvent.fromJson(Map<String, dynamic> json) {
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

    final incomeSource = json['income_source'];

    return IncomeEvent(
      id: toNullableInt(json['id']) ?? 0,
      incomeSourceId: toNullableInt(json['income_source_id']),
      title: json['title']?.toString() ?? '',
      amount: toDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'PEN',
      expectedDate: toNullableDate(json['expected_date']),
      receivedDate: toNullableDate(json['received_date']),
      status: json['status']?.toString() ?? 'planned',
      notes: json['notes']?.toString(),
      incomeSourceName: incomeSource is Map
          ? incomeSource['name']?.toString()
          : null,
    );
  }
}