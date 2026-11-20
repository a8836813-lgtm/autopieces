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
  });
}

class Part {
  final String id;
  final String name;
  final String oem;
  final String category;
  final String fits;

  const Part({
    required this.id,
    required this.name,
    required this.oem,
    required this.category,
    required this.fits,
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
  String status; // 'Pending' or 'Confirmed'

  Reservation({
    required this.item,
    DateTime? createdAt,
    this.status = 'Pending',
  }) : createdAt = createdAt ?? DateTime.now();
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
  final String id;
  final String mechanicId;
  final String mechanicName;
  final String title;
  final String car;
  final String category;
  final String date;
  final String problem;
  final String diagnosis;
  final String workDone;
  final int laborCost;
  final int partsCost;
  final double durationHours;
  final List<String> partsUsed;
  final int warrantyMonths;
  final int helpful;

  const RepairReport({
    required this.id,
    required this.mechanicId,
    required this.mechanicName,
    required this.title,
    required this.car,
    required this.category,
    required this.date,
    required this.problem,
    required this.diagnosis,
    required this.workDone,
    required this.laborCost,
    required this.partsCost,
    required this.durationHours,
    required this.partsUsed,
    required this.warrantyMonths,
    this.helpful = 0,
  });

  int get cost => laborCost + partsCost;
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
