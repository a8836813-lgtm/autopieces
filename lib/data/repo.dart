import 'package:flutter/foundation.dart';

import 'models.dart';

enum SortMode { bestMatch, nearest, cheapest }

/// In-memory data source with sample data.
///
/// For the prototype everything lives here. Later, replace the bodies of
/// these methods with calls to the real backend (FastAPI) and keep the
/// method signatures, so the screens do not need to change.
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
    ),
  ];

  final List<Part> parts = const [
    Part(
      id: 'p1',
      name: 'Front brake disc, ventilated 288 mm',
      oem: '5Q0615301',
      category: 'Brakes',
      fits: 'VW Golf 7 (2013–2020)',
    ),
    Part(
      id: 'p2',
      name: 'Rear brake disc, solid 272 mm',
      oem: '5Q0615601',
      category: 'Brakes',
      fits: 'VW Golf 7 (2013–2020)',
    ),
    Part(
      id: 'p3',
      name: 'Front brake pads, set of 4',
      oem: '5Q0698151',
      category: 'Brakes',
      fits: 'VW Golf 7 (2013–2020)',
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
    ),
    Part(
      id: 'p7',
      name: 'Alloy rim 16 inch, 5x112',
      oem: 'R16-5112',
      category: 'Rims',
      fits: 'VW Golf 7 (2013–2020)',
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
  ];

  final List<Reservation> reservations = [];

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

  final List<RepairReport> reports = const [
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

    final results = <SearchResult>[];
    for (final p in parts) {
      final hay = '${p.name} ${p.fits} ${p.oem} ${p.category}'.toLowerCase();
      final matches = tokens.every((t) => hay.contains(t));
      if (!matches) continue;
      results.addAll(
        resultsForPart(p.id, sort: SortMode.bestMatch, inStockOnly: inStockOnly),
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
}
