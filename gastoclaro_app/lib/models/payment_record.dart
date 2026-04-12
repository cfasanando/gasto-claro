class PaymentRecord {
  final int id;
  final int paymentObligationId;
  final double paidAmount;
  final String currency;
  final DateTime? paidAt;
  final String paymentMethod;
  final String? note;
  final String? obligationTitle;

  PaymentRecord({
    required this.id,
    required this.paymentObligationId,
    required this.paidAmount,
    required this.currency,
    required this.paidAt,
    required this.paymentMethod,
    required this.note,
    required this.obligationTitle,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is int) {
        return value.toDouble();
      }

      if (value is double) {
        return value;
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    int toInt(dynamic value) {
      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? toNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }

      return DateTime.tryParse(value.toString());
    }

    final obligation = json['payment_obligation'];

    return PaymentRecord(
      id: toInt(json['id']),
      paymentObligationId: toInt(json['payment_obligation_id']),
      paidAmount: toDouble(json['paid_amount']),
      currency: json['currency']?.toString() ?? 'PEN',
      paidAt: toNullableDate(json['paid_at']),
      paymentMethod: json['payment_method']?.toString() ?? 'other',
      note: json['note']?.toString(),
      obligationTitle: obligation is Map ? obligation['title']?.toString() : null,
    );
  }
}