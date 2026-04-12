class AppFormatters {
  static const List<String> monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Setiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static String money(num value, [String currency = 'PEN']) {
    final symbol = currency == 'USD' ? r'$' : 'S/';
    return '$symbol ${value.toStringAsFixed(2)}';
  }

  static String date(dynamic value) {
    if (value == null) {
      return '-';
    }

    final date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  static String monthYear(int year, int month) {
    return '${monthNames[month - 1]} $year';
  }

  static String obligationStatus(String? status) {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'partial':
        return 'Parcial';
      case 'pending':
        return 'Pendiente';
      case 'overdue':
        return 'Vencido';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status ?? '-';
    }
  }
}