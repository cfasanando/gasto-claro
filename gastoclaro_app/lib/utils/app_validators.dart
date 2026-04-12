class AppValidators {
  static String? requiredText(
      String? value, {
        required String label,
        int? minLength,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$label es obligatorio';
    }

    if (minLength != null && text.length < minLength) {
      return '$label debe tener al menos $minLength caracteres';
    }

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El correo es obligatorio';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(text)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  static String? requiredPositiveNumber(
      String? value, {
        required String label,
        bool allowZero = false,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$label es obligatorio';
    }

    final number = double.tryParse(text);

    if (number == null) {
      return '$label debe ser un número válido';
    }

    if (allowZero) {
      if (number < 0) {
        return '$label no puede ser negativo';
      }
    } else {
      if (number <= 0) {
        return '$label debe ser mayor que 0';
      }
    }

    return null;
  }

  static String? optionalNumber(
      String? value, {
        required String label,
        bool allowZero = true,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final number = double.tryParse(text);

    if (number == null) {
      return '$label debe ser un número válido';
    }

    if (allowZero) {
      if (number < 0) {
        return '$label no puede ser negativo';
      }
    } else {
      if (number <= 0) {
        return '$label debe ser mayor que 0';
      }
    }

    return null;
  }

  static String? optionalIntegerRange(
      String? value, {
        required String label,
        required int min,
        required int max,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final number = int.tryParse(text);

    if (number == null) {
      return '$label debe ser un número entero';
    }

    if (number < min || number > max) {
      return '$label debe estar entre $min y $max';
    }

    return null;
  }

  static String? optionalDateYmd(String? value, {required String label}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!dateRegex.hasMatch(text)) {
      return '$label debe tener formato YYYY-MM-DD';
    }

    final parsed = DateTime.tryParse(text);

    if (parsed == null) {
      return '$label no es una fecha válida';
    }

    return null;
  }

  static String? requiredDateYmd(String? value, {required String label}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$label es obligatoria';
    }

    return optionalDateYmd(text, label: label);
  }
}