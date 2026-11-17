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

class Mechanic {
  final String id;
  final String name;
  final String specialties;
  final double rating;
  final int reviews;
  final double distanceKm;
  final int reportsCount;
  final bool premium;

  const Mechanic({
    required this.id,
    required this.name,
    required this.specialties,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.reportsCount,
    this.premium = false,
  });
}

class RepairReport {
  final String mechanicName;
  final String title;
  final String car;
  final String problem;
  final String diagnosis;
  final String workDone;
  final int cost;

  const RepairReport({
    required this.mechanicName,
    required this.title,
    required this.car,
    required this.problem,
    required this.diagnosis,
    required this.workDone,
    required this.cost,
  });
}
