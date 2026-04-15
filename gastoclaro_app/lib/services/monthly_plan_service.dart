import '../models/debt.dart';
import '../models/monthly_dashboard.dart';
import '../models/monthly_plan.dart';

class MonthlyPlanService {
  MonthlyPlan buildPlan({
    required MonthlyDashboard dashboard,
    required List<Debt> debts,
  }) {
    final availableNow =
        dashboard.receivedIncomeTotal - dashboard.remainingObligationTotal;

    final projectedBalance =
        dashboard.expectedIncomeTotal - dashboard.remainingObligationTotal;

    final pendingItems = _dedupeItems([
      ...dashboard.attentionItems.map((e) => Map<String, dynamic>.from(e)),
      ...dashboard.pendingItems.map((e) => Map<String, dynamic>.from(e)),
    ]);

    final mustPay = <Map<String, dynamic>>[];
    final payIfExtraIncome = <Map<String, dynamic>>[];
    final canPause = <Map<String, dynamic>>[];

    for (final item in pendingItems) {
      final bucket = classifyObligation(item);

      if (bucket == _PlanBucket.mustPay) {
        mustPay.add(item);
      } else if (bucket == _PlanBucket.canPause) {
        canPause.add(item);
      } else {
        payIfExtraIncome.add(item);
      }
    }

    _sortBucket(mustPay);
    _sortBucket(payIfExtraIncome);
    _sortBucket(canPause);

    final focusDebt = resolveFocusDebt(debts);

    final pressureLevel = resolvePressureLevel(
      availableNow: availableNow,
      projectedBalance: projectedBalance,
    );

    final summary = buildSummary(
      pressureLevel: pressureLevel,
      mustPayCount: mustPay.length,
      projectedBalance: projectedBalance,
      focusDebt: focusDebt,
    );

    return MonthlyPlan(
      availableNow: availableNow,
      projectedBalance: projectedBalance,
      pressureLevel: pressureLevel,
      summary: summary,
      mustPay: mustPay,
      payIfExtraIncome: payIfExtraIncome,
      canPause: canPause,
      focusDebt: focusDebt,
    );
  }

  List<Map<String, dynamic>> _dedupeItems(List<Map<String, dynamic>> items) {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in items) {
      final key =
          '${item['id'] ?? item['title']}-${item['due_date']}-${item['status']}';

      if (!seen.add(key)) {
        continue;
      }

      result.add(item);
    }

    return result;
  }

  void _sortBucket(List<Map<String, dynamic>> items) {
    items.sort((a, b) {
      final aStatus = (a['status']?.toString() ?? '').toLowerCase();
      final bStatus = (b['status']?.toString() ?? '').toLowerCase();

      final statusCompare =
      _statusPriority(aStatus).compareTo(_statusPriority(bStatus));

      if (statusCompare != 0) {
        return statusCompare;
      }

      final aDate = _parseDate(a['due_date']);
      final bDate = _parseDate(b['due_date']);

      if (aDate != null && bDate != null) {
        final dateCompare = aDate.compareTo(bDate);

        if (dateCompare != 0) {
          return dateCompare;
        }
      }

      final aAmount = ((a['amount_due'] as num?) ?? 0).toDouble();
      final bAmount = ((b['amount_due'] as num?) ?? 0).toDouble();

      return bAmount.compareTo(aAmount);
    });
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'overdue':
        return 0;
      case 'partial':
        return 1;
      case 'pending':
        return 2;
      default:
        return 3;
    }
  }

  DateTime? _parseDate(dynamic raw) {
    final value = raw?.toString();

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  _PlanBucket classifyObligation(Map<String, dynamic> item) {
    final title = (item['title']?.toString() ?? '').toLowerCase();
    final status = (item['status']?.toString() ?? '').toLowerCase();

    if (status == 'overdue' || status == 'partial') {
      return _PlanBucket.mustPay;
    }

    const criticalKeywords = [
      'alquiler',
      'luz',
      'agua',
      'internet',
      'celular',
      'niko',
      'scotiabank',
      'utp',
      'zegel',
      'universidad',
    ];

    const pauseKeywords = [
      'gym',
      'suplementos',
    ];

    final isCritical =
    criticalKeywords.any((keyword) => title.contains(keyword));

    if (isCritical) {
      return _PlanBucket.mustPay;
    }

    final isPausable =
    pauseKeywords.any((keyword) => title.contains(keyword));

    if (isPausable) {
      return _PlanBucket.canPause;
    }

    return _PlanBucket.payIfExtraIncome;
  }

  Debt? resolveFocusDebt(List<Debt> debts) {
    final activeDebts = debts
        .where((debt) => debt.status == 'active' && debt.currentBalance > 0)
        .toList();

    if (activeDebts.isEmpty) {
      return null;
    }

    activeDebts.sort((a, b) {
      final aPriority = debtPriorityScore(a);
      final bPriority = debtPriorityScore(b);

      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      return a.currentBalance.compareTo(b.currentBalance);
    });

    return activeDebts.first;
  }

  int debtPriorityScore(Debt debt) {
    final name = debt.name.toLowerCase();
    final creditor = (debt.creditorName ?? '').toLowerCase();

    int score = 0;

    if (name.contains('niko') || creditor.contains('scotiabank')) {
      score += 100;
    }

    if ((debt.interestRateMonthly ?? 0) >= 3) {
      score += 25;
    }

    if (debt.hasFixedPayment) {
      score += 10;
    }

    if ((debt.monthlyDueAmount ?? 0) > 0) {
      score += 10;
    }

    return score;
  }

  String resolvePressureLevel({
    required double availableNow,
    required double projectedBalance,
  }) {
    if (availableNow < 0) {
      return 'critical';
    }

    if (projectedBalance < 0) {
      return 'tight';
    }

    if (projectedBalance <= 300) {
      return 'stable';
    }

    return 'surplus';
  }

  String buildSummary({
    required String pressureLevel,
    required int mustPayCount,
    required double projectedBalance,
    required Debt? focusDebt,
  }) {
    switch (pressureLevel) {
      case 'critical':
        return 'Tu caja actual no cubre lo pendiente. Prioriza solo lo crítico.';
      case 'tight':
        return 'El mes podría cerrar justo. Cubre lo esencial y evita extras.';
      case 'stable':
        return 'Tu mes está controlado, pero con poco margen para desorden.';
      case 'surplus':
        return focusDebt != null
            ? 'Hay margen para adelantar la deuda foco: ${focusDebt.name}.'
            : 'Hay margen positivo este mes.';
      default:
        return '$mustPayCount pago(s) requieren atención este mes.';
    }
  }
}

enum _PlanBucket {
  mustPay,
  payIfExtraIncome,
  canPause,
}