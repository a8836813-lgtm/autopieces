import 'package:flutter/foundation.dart';

import '../models/search_query.dart';
import 'models.dart';
import 'vehicles.dart';

enum SortMode { bestMatch, nearest, cheapest }

class Repo extends ChangeNotifier {
  Repo._();
  static final Repo instance = Repo._();

  /// The shop that the "shop mode" demo is logged in as.
  static const String myShopId = 's1';

  final List<Shop> shops = const [
    Shop(
      id: 's1',
      name: 'Hamid Grossiste Auto',
      type: 'Wholesale · brakes, filters, suspension',
      distanceKm: 1.2,
      rating: 4.7,
      partsCount: 1240,
      hours: 'Open until 19:00',
      openNow: true,
      phone: '0550 10 20 30',
      bearing: 40,
    ),
    Shop(
      id: 's2',
      name: 'Pièces Auto Belkacem',
      type: 'Retail · all makes',
      distanceKm: 2.1,
      rating: 4.5,
      partsCount: 860,
      hours: 'Open until 18:30',
      openNow: true,
      phone: '0550 11 22 33',
      bearing: 120,
    ),
    Shop(
      id: 's3',
      name: 'Garage Parts El Wiam',
      type: 'Retail · European cars',
      distanceKm: 2.8,
      rating: 4.4,
      partsCount: 610,
      hours: 'Open until 18:00',
      openNow: true,
      phone: '0550 44 55 66',
      bearing: 200,
    ),
    Shop(
      id: 's4',
      name: 'Pneus et Jantes Sofiane',
      type: 'Tires and rims',
      distanceKm: 3.4,
      rating: 4.8,
      partsCount: 320,
      hours: 'Open until 19:30',
      openNow: true,
      phone: '0550 77 88 99',
      bearing: 280,
    ),
    Shop(
      id: 's5',
      name: 'Batterie Express Jijel',
      type: 'Batteries and electrical',
      distanceKm: 4.5,
      rating: 4.3,
      partsCount: 190,
      hours: 'Opens at 08:00',
      openNow: false,
      phone: '0550 12 34 56',
      bearing: 330,
    ),
  ];

  final List<Part> parts = [
    Part(
      id: 'p1',
      name: 'Front brake disc, ventilated 288 mm',
      oem: '5Q0615301',
      category: 'Brakes',
      fits: 'VW Golf 7 (2013–2020)',
      fitments: [
        Fitment('volkswagen', 'Golf 7'),
      ],
    ),
    Part(
      id: 'p2',
      name: 'Rear brake disc, solid 272 mm',
      oem: '5Q0615601',
      category: 'Brakes',
      fits: 'VW Golf 7 (2013–2020)',
      fitments: [
        Fitment('volkswagen', 'Golf 7'),
      ],
    ),
    Part(
      id: 'p3',
      name: 'Front brake pads, set of 4',
      oem: '5Q0698151',
      category: 'Brakes',
      fits: 'VW Golf 7 (2013–2020)',
      fitments: [
        Fitment('volkswagen', 'Golf 7'),
      ],
    ),
    Part(
      id: 'p4',
      name: 'Tire 205/55 R16 91V',
      oem: '205/55R16',
      category: 'Tires',
      fits: 'Most compact cars',
    ),
    Part(
      id: 'p5',
      name: 'Car battery 12V 60Ah',
      oem: 'B60-12',
      category: 'Battery',
      fits: 'Most petrol and diesel cars',
    ),
    Part(
      id: 'p6',
      name: 'Oil filter',
      oem: '04E115561H',
      category: 'Filters',
      fits: 'VW Golf 7 (2013–2020)',
      fitments: [
        Fitment('volkswagen', 'Golf 7'),
      ],
    ),
    Part(
      id: 'p7',
      name: 'Alloy rim 16 inch, 5x112',
      oem: 'R16-5112',
      category: 'Rims',
      fits: 'VW Golf 7 (2013–2020)',
      fitments: [
        Fitment('volkswagen', 'Golf 7'),
      ],
    ),
    Part(
      id: 'p8',
      name: 'Engine oil 5W-30, 5 L',
      oem: '5W30-5L',
      category: 'Engine',
      fits: 'Most petrol and diesel cars',
    ),
    Part(
      id: 'p9',
      name: 'Front brake disc, ventilated 280 mm',
      oem: '1K0615301',
      category: 'Brakes',
      fits: 'VW Golf 5 and 6',
      fitments: [
        Fitment('volkswagen', 'Golf 5'),
        Fitment('volkswagen', 'Golf 6'),
      ],
    ),
    // Demo truck part with a made-up serial number, so Trucks search shows
    // something. Replace with real data later.
    Part(
      id: 'p10',
      name: 'Air filter, heavy duty',
      oem: 'DEMO-TRK-1001',
      category: 'Filters',
      fits: 'Volvo Trucks FH and FM',
      fitments: [
        Fitment('volvo_trucks', 'FH'),
        Fitment('volvo_trucks', 'FM'),
      ],
    ),
  ];

  final List<StockItem> stock = [
    StockItem(shopId: 's1', partId: 'p1', quantity: 6, price: 7900),
    StockItem(shopId: 's2', partId: 'p1', quantity: 4, price: 8200),
    StockItem(shopId: 's3', partId: 'p1', quantity: 2, price: 7600),
    StockItem(shopId: 's1', partId: 'p2', quantity: 3, price: 6300),
    StockItem(shopId: 's2', partId: 'p2', quantity: 3, price: 6500),
    StockItem(shopId: 's1', partId: 'p3', quantity: 12, price: 3900),
    StockItem(shopId: 's2', partId: 'p3', quantity: 1, price: 4200),
    StockItem(shopId: 's3', partId: 'p3', quantity: 5, price: 4100),
    StockItem(shopId: 's4', partId: 'p4', quantity: 8, price: 14600),
    StockItem(shopId: 's2', partId: 'p4', quantity: 3, price: 15250),
    StockItem(shopId: 's5', partId: 'p5', quantity: 5, price: 12000),
    StockItem(shopId: 's3', partId: 'p5', quantity: 2, price: 12500),
    StockItem(shopId: 's1', partId: 'p6', quantity: 20, price: 900),
    StockItem(shopId: 's3', partId: 'p6', quantity: 9, price: 950),
    StockItem(shopId: 's4', partId: 'p7', quantity: 2, price: 16500),
    StockItem(shopId: 's1', partId: 'p8', quantity: 7, price: 6200),
    StockItem(shopId: 's2', partId: 'p8', quantity: 4, price: 6400),
    StockItem(shopId: 's1', partId: 'p10', quantity: 4, price: 11500),
  ];

  final List<Reservation> reservations = [];

  /// The mechanic that the "mechanic mode" demo is logged in as.
  static const String myMechanicId = 'm1';
  static const String myMechanicName = 'Garage El Amel';

  /// Saved by the client (demo has a single client).
  final Set<String> favoriteShopIds = {};
  final Set<String> favoritePartIds = {};

  /// Counters for the shop "Insights" tab. Each call or view is logged so the
  /// platform can charge per lead later (CONTACT_REVEALS in the data model).
  final Map<String, int> viewsByShop = {};
  final Map<String, int> callsByShop = {};

  final List<Review> reviews = [
    Review(
      targetId: 's1',
      author: 'Yacine M.',
      stars: 5,
      comment: 'Had the exact discs for my Golf, fair price.',
      createdAt: DateTime(2026, 10, 2),
    ),
    Review(
      targetId: 's1',
      author: 'Samir K.',
      stars: 4,
      comment: 'Good stock, a bit busy in the morning.',
      createdAt: DateTime(2026, 10, 20),
    ),
    Review(
      targetId: 's2',
      author: 'Nadia B.',
      stars: 4,
      comment: 'Found the pads I needed in minutes.',
      createdAt: DateTime(2026, 9, 14),
    ),
    Review(
      targetId: 'm1',
      author: 'Karim L.',
      stars: 5,
      comment: 'Diagnosed the noise quickly and explained everything.',
      createdAt: DateTime(2026, 10, 8),
    ),
    Review(
      targetId: 'm2',
      author: 'Amine D.',
      stars: 4,
      comment: 'Honest work on my gearbox.',
      createdAt: DateTime(2026, 9, 30),
    ),
  ];

  final List<Mechanic> mechanics = const [
    Mechanic(
      id: 'm1',
      name: 'Garage El Amel',
      specialties: 'Brakes, suspension, diagnostics',
      rating: 4.8,
      reviews: 37,
      distanceKm: 1.2,
      reportsCount: 14,
      premium: true,
    ),
    Mechanic(
      id: 'm2',
      name: 'Atelier Mécanique Nour',
      specialties: 'Engine, gearbox',
      rating: 4.5,
      reviews: 21,
      distanceKm: 3.4,
      reportsCount: 8,
    ),
    Mechanic(
      id: 'm3',
      name: 'Karim B. Auto Service',
      specialties: 'Electrical, air conditioning',
      rating: 4.2,
      reviews: 9,
      distanceKm: 5.1,
      reportsCount: 3,
    ),
  ];

  final List<RepairReport> reports = [
    RepairReport(
      mechanicName: 'Garage El Amel',
      title: 'Grinding noise on braking, worse at low speed',
      car: 'VW Golf 7 · 2016',
      problem:
          'Customer reported a metallic grinding from the front wheels when braking, with a slight pull to the right.',
      diagnosis:
          'Front pads worn to the backing plate, scoring on both discs, and a seized caliper slider on the right side.',
      workDone:
          'Replaced discs and pads, cleaned and greased the slider pins, bled the brake fluid.',
      cost: 24000,
    ),
    RepairReport(
      mechanicName: 'Atelier Mécanique Nour',
      title: 'Squeal and vibration through the brake pedal',
      car: 'Renault Clio 4 · 2015',
      problem:
          'High-pitched squeal when braking and a pulsing pedal during longer stops from motorway speed.',
      diagnosis:
          'Warped front discs from overheating; pads glazed. Rear brakes within limits.',
      workDone:
          'Replaced front discs and pads, checked hub runout, road test after bedding in.',
      cost: 19500,
    ),
    RepairReport(
      mechanicName: 'Karim B. Auto Service',
      title: 'Battery drains overnight',
      car: 'Peugeot 208 · 2018',
      problem: 'The car will not start after standing for one night.',
      diagnosis:
          'Parasitic current draw from a faulty door control module. The battery itself was healthy.',
      workDone: 'Replaced the door module and tested the draw with a meter.',
      cost: 9000,
    ),
  ];

  // ---------------------------------------------------------------- lookups

  Shop shopById(String id) => shops.firstWhere((s) => s.id == id);

  Part partById(String id) => parts.firstWhere((p) => p.id == id);

  StockItem? stockFor(String shopId, String partId) {
    for (final s in stock) {
      if (s.shopId == shopId && s.partId == partId) return s;
    }
    return null;
  }

  List<StockItem> stockOfShop(String shopId) =>
      stock.where((s) => s.shopId == shopId).toList();

  // ----------------------------------------------------------------- search

  /// Shops that hold exactly this part.
  List<SearchResult> resultsForPart(
    String partId, {
    SortMode sort = SortMode.bestMatch,
    bool inStockOnly = true,
  }) {
    final part = partById(partId);
    final list = <SearchResult>[];
    for (final s in stock) {
      if (s.partId != partId) continue;
      if (inStockOnly && s.quantity <= 0) continue;
      list.add(SearchResult(part: part, shop: shopById(s.shopId), stock: s));
    }
    _sort(list, sort);
    return list;
  }

  /// Free-text search: every word must appear in the part name, number,
  /// category or the cars it fits.
  List<SearchResult> search(
    String query, {
    SortMode sort = SortMode.bestMatch,
    bool inStockOnly = true,
  }) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];
    final serial = SearchQuery.normalizeSerial(query);

    final results = <SearchResult>[];
    for (final p in parts) {
      final hay = '${p.name} ${p.fits} ${p.oem} ${p.category}'.toLowerCase();
      final matches = tokens.every((t) => hay.contains(t)) ||
          (serial.length >= 4 && _serialMatches(p, serial));
      if (!matches) continue;
      results.addAll(
        resultsForPart(p.id,
            sort: SortMode.bestMatch, inStockOnly: inStockOnly),
      );
    }
    _sort(results, sort);
    return results;
  }

  /// True when [serial] (already normalized) is part of the part's serial
  /// number or of one of its other serial numbers.
  bool _serialMatches(Part p, String serial) {
    if (SearchQuery.normalizeSerial(p.oem).contains(serial)) return true;
    return p.altSerials
        .any((a) => SearchQuery.normalizeSerial(a).contains(serial));
  }

  /// Does this part fit the vehicle chosen in [q]? Parts with no fitment list
  /// are universal and fit any car (but not trucks).
  bool _fitsVehicle(Part p, SearchQuery q) {
    final brand = q.brand;
    if (brand == null) return true;
    if (p.fitments.isEmpty) return brand.type == VehicleType.car;
    return p.fitments.any(
      (f) =>
          f.brandId == brand.id &&
          (q.model == null || f.model == null || f.model == q.model),
    );
  }

  /// Search by part serial number and/or vehicle (brand and model).
  /// When both are given, the part must match both.
  List<SearchResult> searchVehicle(
    SearchQuery q, {
    SortMode sort = SortMode.bestMatch,
    bool inStockOnly = true,
  }) {
    final serial = q.serial;
    final results = <SearchResult>[];
    for (final p in parts) {
      if (serial != null && !_serialMatches(p, serial)) continue;
      if (!_fitsVehicle(p, q)) continue;
      results.addAll(
        resultsForPart(p.id,
            sort: SortMode.bestMatch, inStockOnly: inStockOnly),
      );
    }
    _sort(results, sort);
    return results;
  }

  void _sort(List<SearchResult> list, SortMode sort) {
    switch (sort) {
      case SortMode.nearest:
        {
          list.sort((a, b) => a.shop.distanceKm.compareTo(b.shop.distanceKm));
        }
      case SortMode.cheapest:
        {
          list.sort((a, b) => a.stock.price.compareTo(b.stock.price));
        }
      case SortMode.bestMatch:
        {
          // Simple weighted score: closer, cheaper and better rated is better.
          double score(SearchResult r) =>
              r.shop.distanceKm + r.stock.price / 2000.0 - r.shop.rating;
          list.sort((a, b) => score(a).compareTo(score(b)));
        }
    }
  }

  List<RepairReport> searchReports(String query) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return reports;
    return reports.where((r) {
      final hay =
          '${r.title} ${r.car} ${r.problem} ${r.diagnosis} ${r.workDone}'
              .toLowerCase();
      return tokens.every((t) => hay.contains(t));
    }).toList();
  }

  // ---------------------------------------------------------------- changes

  void upsertStock({
    required String shopId,
    required String partId,
    required int quantity,
    required int price,
    required String condition,
  }) {
    final existing = stockFor(shopId, partId);
    if (existing != null) {
      existing.quantity = quantity;
      existing.price = price;
      existing.condition = condition;
    } else {
      stock.add(
        StockItem(
          shopId: shopId,
          partId: partId,
          quantity: quantity,
          price: price,
          condition: condition,
        ),
      );
    }
    notifyListeners();
  }

  void reserve(SearchResult result) {
    reservations.insert(0, Reservation(item: result));
    notifyListeners();
  }

  void confirmReservation(Reservation reservation) {
    reservation.status = 'Confirmed';
    notifyListeners();
  }

  // -------------------------------------------------------------- favorites

  bool isFavoriteShop(String shopId) => favoriteShopIds.contains(shopId);
  bool isFavoritePart(String partId) => favoritePartIds.contains(partId);

  void toggleFavoriteShop(String shopId) {
    if (!favoriteShopIds.remove(shopId)) favoriteShopIds.add(shopId);
    notifyListeners();
  }

  void toggleFavoritePart(String partId) {
    if (!favoritePartIds.remove(partId)) favoritePartIds.add(partId);
    notifyListeners();
  }

  // ---------------------------------------------------------------- reviews

  List<Review> reviewsFor(String targetId) =>
      reviews.where((r) => r.targetId == targetId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Average of the written reviews, or null when there are none.
  double? averageStars(String targetId) {
    final list = reviewsFor(targetId);
    if (list.isEmpty) return null;
    return list.fold<int>(0, (sum, r) => sum + r.stars) / list.length;
  }

  void addReview({
    required String targetId,
    required int stars,
    required String comment,
    String author = 'You',
  }) {
    reviews.add(
      Review(
        targetId: targetId,
        author: author,
        stars: stars,
        comment: comment.trim(),
      ),
    );
    notifyListeners();
  }

  // ----------------------------------------------------------- reservations

  void cancelReservation(Reservation r) {
    if (!r.isActive) return;
    r.status = 'Cancelled';
    notifyListeners();
  }

  /// The shop owner marks the part as picked up. One unit leaves the stock.
  void completeReservation(Reservation r) {
    if (r.status != 'Confirmed') return;
    r.status = 'Completed';
    final item = r.item.stock;
    if (item.quantity > 0) item.quantity--;
    notifyListeners();
  }

  void markReviewed(Reservation r) {
    r.reviewed = true;
    notifyListeners();
  }

  /// Reviews are only allowed for completed reservations.
  Reservation? reviewableReservationAt(String shopId) {
    for (final r in reservations) {
      if (r.item.shop.id == shopId && r.status == 'Completed' && !r.reviewed) {
        return r;
      }
    }
    return null;
  }

  // ------------------------------------------------------------------ stats

  void logView(String shopId) {
    viewsByShop[shopId] = (viewsByShop[shopId] ?? 0) + 1;
  }

  void logCall(String shopId) {
    callsByShop[shopId] = (callsByShop[shopId] ?? 0) + 1;
    notifyListeners();
  }

  int reservationsCountFor(String shopId) =>
      reservations.where((r) => r.item.shop.id == shopId).length;

  // ---------------------------------------------------------------- reports

  List<RepairReport> reportsOf(String mechanicName) =>
      reports.where((r) => r.mechanicName == mechanicName).toList();

  void addReport(RepairReport report) {
    reports.insert(0, report);
    notifyListeners();
  }

  // ------------------------------------------------------------------ parts

  /// The catalog part with this serial number (or one of its other serial
  /// numbers), or null. Spaces, dashes and case are ignored.
  Part? partBySerial(String serial) {
    final wanted = SearchQuery.normalizeSerial(serial);
    if (wanted.isEmpty) return null;
    for (final p in parts) {
      if (SearchQuery.normalizeSerial(p.oem) == wanted) return p;
      if (p.altSerials.any((a) => SearchQuery.normalizeSerial(a) == wanted)) {
        return p;
      }
    }
    return null;
  }

  /// Adds a new part to the catalog (shop owner "add by serial number").
  Part addPart({
    required String name,
    required String serial,
    required String category,
    required String fits,
    List<Fitment> fitments = const [],
  }) {
    final part = Part(
      id: 'p${parts.length + 1}',
      name: name.trim(),
      oem: serial.trim().toUpperCase(),
      category: category,
      fits: fits,
      fitments: fitments,
    );
    parts.add(part);
    notifyListeners();
    return part;
  }
}
