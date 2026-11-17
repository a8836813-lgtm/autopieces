/// Form validators shared by login and sign-up.
class Validators {
  static String? required(String? v, [String label = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  /// Algerian mobile: 05/06/07 + 8 digits, or +213 5/6/7 + 8 digits.
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final s = v.replaceAll(RegExp(r'[\s\-.]'), '');
    final ok = RegExp(r'^(0|\+213)[567]\d{8}$').hasMatch(s);
    return ok ? null : 'Use a valid Algerian mobile (e.g. 0550123456)';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  static String? Function(String?) confirm(String Function() original) {
    return (v) {
      if (v == null || v.isEmpty) return 'Confirm your password';
      return v == original() ? null : 'Passwords do not match';
    };
  }

  static String? years(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0 || n > 60) return 'Enter a number from 0 to 60';
    return null;
  }
}
