class Shop {
  final String id;
  final String name;
  final String type;
  final double distanceKm;
  final double rating;
  final int partsCount;
  final String hours;
  final bool openNow;
  final String phone;

  /// Direction from the client in degrees (0 = north). Used by the nearby
  /// map until real GPS coordinates exist.
  final double bearing;

  const Shop({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.rating,
    required this.partsCount,
    required this.hours,
    required this.openNow,
    required this.phone,
    this.bearing = 0,
  });
}

/// A vehicle a part fits. [model] null means every model of that brand.
/// [brandId] matches `VehicleBrand.id` in `data/vehicles.dart`.
class Fitment {
  final String brandId;
  final String? model;

  const Fitment(this.brandId, [this.model]);
}

class Part {
  final String id;
  final String name;

  /// The part serial number (OEM number). Universal: it identifies the part
  /// whatever the brand of the car.
  final String oem;
  final String category;
  final String fits;

  /// Other serial numbers of the same part (aftermarket cross-references).
  final List<String> altSerials;

  /// Vehicles this part fits. Empty means universal (fits most cars).
  final List<Fitment> fitments;

  const Part({
    required this.id,
    required this.name,
    required this.oem,
    required this.category,
    required this.fits,
    this.altSerials = const [],
    this.fitments = const [],
  });
}

/// One part held by one shop. Mutable so the shop owner can edit it.
class StockItem {
  final String shopId;
  final String partId;
  int quantity;
  int price; // in DZD
  String condition; // 'New' or 'Used'

  StockItem({
    required this.shopId,
    required this.partId,
    required this.quantity,
    required this.price,
    this.condition = 'New',
  });
}

class MatchCandidate {
  final Part part;
  final double confidence; // 0.0 to 1.0
  final String reason;

  const MatchCandidate({
    required this.part,
    required this.confidence,
    required this.reason,
  });
}

class SearchResult {
  final Part part;
  final Shop shop;
  final StockItem stock;

  const SearchResult({
    required this.part,
    required this.shop,
    required this.stock,
  });
}

class Reservation {
  final SearchResult item;
  final DateTime createdAt;

  /// 'Pending' -> 'Confirmed' -> 'Completed', or 'Cancelled' by the client.
  String status;

  /// True once the client has reviewed the shop for this reservation.
  bool reviewed;

  Reservation({
    required this.item,
    DateTime? createdAt,
    this.status = 'Pending',
    this.reviewed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == 'Pending' || status == 'Confirmed';
}

/// One service a mechanic offers, with a starting price in DZD.
class MechanicService {
  final String name;
  final int priceFrom;

  const MechanicService(this.name, this.priceFrom);
}

class Mechanic {
  final String id;
  final String name;
  final List<String> specialties;
  final double rating;
  final int reviews;
  final double distanceKm;
  final bool premium;
  final bool verified;
  final int yearsExperience;
  final String address;
  final String phone;
  final String hours;
  final bool openNow;
  final String about;
  final String responseTime;
  final List<String> languages;
  final bool mobileService;
  final List<MechanicService> services;

  const Mechanic({
    required this.id,
    required this.name,
    required this.specialties,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.address,
    required this.phone,
    required this.hours,
    required this.openNow,
    required this.about,
    required this.services,
    this.premium = false,
    this.verified = false,
    this.yearsExperience = 0,
    this.responseTime = 'Replies within a day',
    this.languages = const ['Arabic', 'French'],
    this.mobileService = false,
  });

  /// Two-letter monogram used for the avatar.
  String get initials {
    final words =
        name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words[0][0];
    final second = words.length > 1 ? words[1][0] : '';
    return (first + second).toUpperCase();
  }

  /// Lowest starting price across the services, or 0 when none are listed.
  int get cheapestService => services.isEmpty
      ? 0
      : services.map((s) => s.priceFrom).reduce((a, b) => a < b ? a : b);
}

class RepairReport {
  final String mechanicName;
  final String title;
  final String car;
  final String problem;
  final String diagnosis;
  final String workDone;

  /// Total cost in DZD (labor and parts).
  final int cost;
  final String parts;

  // Optional details, used by the report cards.
  final String id;
  final String mechanicId;
  final String category;
  final String date;
  final int laborCost;
  final int partsCost;
  final double durationHours;
  final List<String> partsUsed;
  final int warrantyMonths;
  final int helpful;

  const RepairReport({
    required this.mechanicName,
    required this.title,
    required this.car,
    required this.problem,
    required this.diagnosis,
    required this.workDone,
    required this.cost,
    this.parts = '',
    this.id = '',
    this.mechanicId = '',
    this.category = '',
    this.date = '',
    this.laborCost = 0,
    this.partsCost = 0,
    this.durationHours = 0,
    this.partsUsed = const [],
    this.warrantyMonths = 0,
    this.helpful = 0,
  });

  /// Key used for "helpful" votes (reports written in the app have no id).
  String get key => id.isNotEmpty ? id : '$mechanicName|$title';
}

/// A rating and comment about a shop or a mechanic ([targetId]).
class Review {
  final String targetId;
  final String author;
  final int stars; // 1 to 5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.targetId,
    required this.author,
    required this.stars,
    required this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// An appointment the client asked a mechanic for (demo, kept in memory).
class AppointmentRequest {
  final Mechanic mechanic;
  final String service;
  final DateTime when;
  final String note;
  final DateTime createdAt;
  String status; // 'Sent' or 'Cancelled'

  AppointmentRequest({
    required this.mechanic,
    required this.service,
    required this.when,
    this.note = '',
    DateTime? createdAt,
    this.status = 'Sent',
  }) : createdAt = createdAt ?? DateTime.now();
}

/// A job a client asked the logged-in mechanic for (demo, kept in memory).
///
/// Status flow: New -> Accepted -> In progress -> Done, or New -> Declined.
class JobRequest {
  final String id;
  final String clientName;
  final String car;
  final String problem;
  final double distanceKm;

  /// Quoted price in DZD.
  final int price;

  /// When the client wants the job done.
  final DateTime slot;
  final bool urgent;
  final DateTime createdAt;
  String status;

  /// Set when the job is marked as done (used for earnings).
  DateTime? completedAt;

  JobRequest({
    required this.id,
    required this.clientName,
    required this.car,
    required this.problem,
    required this.distanceKm,
    required this.price,
    required this.slot,
    this.urgent = false,
    this.status = 'New',
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == 'Accepted' || status == 'In progress';
}

/// One badge the mechanic can earn.
class MechanicBadge {
  final String id;
  final String title;
  final String hint;
  final bool earned;

  const MechanicBadge({
    required this.id,
    required this.title,
    required this.hint,
    required this.earned,
  });
}
