import '../data/vehicles.dart';

/// What the user asked for. Pass it to your results screen / backend.
class SearchQuery {
  final VehicleType type;
  final VehicleBrand? brand;
  final String? model;

  /// Part serial number as typed by the user (trimmed).
  final String? serialRaw;

  const SearchQuery({
    required this.type,
    this.brand,
    this.model,
    this.serialRaw,
  });

  /// Serial number used for matching: uppercase letters and digits only,
  /// so "1K0 698-151 A" and "1k0698151a" are the same part number.
  String? get serial {
    final s = normalizeSerial(serialRaw ?? '');
    return s.isEmpty ? null : s;
  }

  bool get hasVehicle => brand != null;
  bool get isEmpty => brand == null && serial == null;

  String get description {
    final parts = <String>[
      if (serial != null) 'Part $serial',
      if (brand != null) brand!.name,
      if (model != null) model!,
    ];
    return parts.join(' · ');
  }

  static String normalizeSerial(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// null when valid (an empty serial is valid: it is optional).
  static String? validateSerial(String? input) {
    final s = normalizeSerial(input ?? '');
    if (s.isEmpty) return null;
    if (s.length < 4) return 'Serial number is too short';
    if (s.length > 30) return 'Serial number is too long';
    return null;
  }
}
