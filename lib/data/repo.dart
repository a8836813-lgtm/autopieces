import 'package:flutter/foundation.dart';

import 'models.dart';

enum SortMode { bestMatch, nearest, cheapest }

enum MechanicSort { topRated, nearest, mostReports }

enum ReportSort { mostHelpful, lowestCost, fastest }

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

  /// Repair categories shared by mechanics (what they do) and reports.
  static const List<String> categories = [
    'Brakes',
    'Suspension',
    'Engine',
    'Gearbox',
    'Electrical',
    'Air conditioning',
    'Diagnostics',
  ];

  final List<Mechanic> mechanics = const [
    Mechanic(
      id: 'm1',
      name: 'Garage El Amel',
      specialties: ['Brakes', 'Suspension', 'Diagnostics'],
      rating: 4.8,
      reviews: 37,
      distanceKm: 1.2,
      premium: true,
      verified: true,
      yearsExperience: 14,
      address: 'Rue du 1er Novembre, Jijel',
      phone: '0770 21 43 65',
      hours: 'Open until 18:30',
      openNow: true,
      about:
          'Family garage focused on braking and suspension work for European '
          'compacts. Every job starts with a written diagnosis and a price '
          'before any part is ordered.',
      responseTime: 'Replies within 1 hour',
      languages: ['Arabic', 'French'],
      mobileService: false,
      services: [
        MechanicService('Front brake pads and discs', 12000),
        MechanicService('Brake fluid change and bleed', 3500),
        MechanicService('Suspension check and repair', 6000),
        MechanicService('Computer diagnostics', 2500),
      ],
    ),
    Mechanic(
      id: 'm2',
      name: 'Atelier Mécanique Nour',
      specialties: ['Engine', 'Gearbox', 'Brakes'],
      rating: 4.5,
      reviews: 21,
      distanceKm: 3.4,
      verified: true,
      yearsExperience: 11,
      address: "Zone d'activité Kaous, Jijel",
      phone: '0661 33 54 76',
      hours: 'Open until 17:30',
      openNow: true,
      about:
          'Engine and gearbox specialists. Timing belts, cooling system '
          'faults and clutch jobs are done in-house with parts warranty.',
      responseTime: 'Replies within 3 hours',
      languages: ['Arabic', 'French', 'English'],
      mobileService: false,
      services: [
        MechanicService('Engine diagnostics', 3000),
        MechanicService('Timing belt kit replacement', 18000),
        MechanicService('Gearbox oil service', 7500),
        MechanicService('Clutch replacement', 25000),
      ],
    ),
    Mechanic(
      id: 'm3',
      name: 'Karim B. Auto Service',
      specialties: ['Electrical', 'Air conditioning'],
      rating: 4.2,
      reviews: 9,
      distanceKm: 5.1,
      verified: false,
      yearsExperience: 6,
      address: 'Cité 5 Juillet, Jijel',
      phone: '0550 47 28 19',
      hours: 'Open until 19:00',
      openNow: true,
      about:
          'Auto electrician. Battery and charging faults, wiring problems '
          'and air conditioning recharge and leak tests.',
      responseTime: 'Replies within a day',
      languages: ['Arabic', 'French'],
      mobileService: true,
      services: [
        MechanicService('Battery and charging test', 1000),
        MechanicService('A/C recharge and leak test', 5500),
        MechanicService('Alternator replacement', 9000),
        MechanicService('Wiring fault tracing', 4000),
      ],
    ),
    Mechanic(
      id: 'm4',
      name: 'Auto Diagnostic Plus',
      specialties: ['Diagnostics', 'Electrical', 'Engine'],
      rating: 4.6,
      reviews: 18,
      distanceKm: 2.3,
      verified: true,
      yearsExperience: 9,
      address: 'Route de Taher, Jijel',
      phone: '0775 62 90 14',
      hours: 'Open until 18:00',
      openNow: true,
      about:
          'Diagnostic center with multi-brand scan tools. Good first stop '
          'when a warning light is on and you do not know why.',
      responseTime: 'Replies within 2 hours',
      languages: ['Arabic', 'French'],
      mobileService: false,
      services: [
        MechanicService('Full OBD diagnostic', 2500),
        MechanicService('Fault clearing and coding', 5000),
        MechanicService('Sensor replacement', 4000),
        MechanicService('Pre-purchase inspection', 6000),
      ],
    ),
    Mechanic(
      id: 'm5',
      name: 'Mécanique Générale Rachid',
      specialties: ['Engine', 'Gearbox', 'Suspension'],
      rating: 4.0,
      reviews: 12,
      distanceKm: 6.8,
      verified: false,
      yearsExperience: 22,
      address: "Boulevard de l'ALN, Jijel",
      phone: '0556 18 37 52',
      hours: 'Closed · opens 08:00',
      openNow: false,
      about:
          'Long-established general garage for older cars. Servicing, '
          'shocks and simple gearbox work at fair prices.',
      responseTime: 'Replies within a day',
      languages: ['Arabic', 'French'],
      mobileService: false,
      services: [
        MechanicService('Oil and filter service', 3000),
        MechanicService('Shock absorber replacement', 10000),
        MechanicService('General inspection', 2000),
      ],
    ),
  ];

  final List<RepairReport> reports = const [
    RepairReport(
      id: 'r1',
      mechanicId: 'm1',
      mechanicName: 'Garage El Amel',
      title: 'Grinding noise on braking, worse at low speed',
      car: 'VW Golf 7 · 2016',
      category: 'Brakes',
      date: 'Oct 2026',
      problem:
          'Customer reported a metallic grinding from the front wheels when braking, with a slight pull to the right.',
      diagnosis:
          'Front pads worn to the backing plate, scoring on both discs, and a seized caliper slider on the right side.',
      workDone:
          'Replaced discs and pads, cleaned and greased the slider pins, bled the brake fluid.',
      laborCost: 8000,
      partsCost: 16000,
      durationHours: 3.5,
      partsUsed: [
        'Front brake discs (pair)',
        'Front brake pads',
        'Brake fluid DOT 4',
      ],
      warrantyMonths: 6,
      helpful: 23,
    ),
    RepairReport(
      id: 'r2',
      mechanicId: 'm2',
      mechanicName: 'Atelier Mécanique Nour',
      title: 'Squeal and vibration through the brake pedal',
      car: 'Renault Clio 4 · 2015',
      category: 'Brakes',
      date: 'Sep 2026',
      problem:
          'High-pitched squeal when braking and a pulsing pedal during longer stops from motorway speed.',
      diagnosis:
          'Warped front discs from overheating; pads glazed. Rear brakes within limits.',
      workDone:
          'Replaced front discs and pads, checked hub runout, road test after bedding in.',
      laborCost: 6500,
      partsCost: 13000,
      durationHours: 2.5,
      partsUsed: ['Front brake discs (pair)', 'Front brake pads'],
      warrantyMonths: 6,
      helpful: 11,
    ),
    RepairReport(
      id: 'r3',
      mechanicId: 'm3',
      mechanicName: 'Karim B. Auto Service',
      title: 'Battery drains overnight',
      car: 'Peugeot 208 · 2018',
      category: 'Electrical',
      date: 'Aug 2026',
      problem: 'The car will not start after standing for one night.',
      diagnosis:
          'Parasitic current draw from a faulty door control module. The battery itself was healthy.',
      workDone: 'Replaced the door module and tested the draw with a meter.',
      laborCost: 4500,
      partsCost: 4500,
      durationHours: 2,
      partsUsed: ['Door control module'],
      warrantyMonths: 3,
      helpful: 17,
    ),
    RepairReport(
      id: 'r4',
      mechanicId: 'm1',
      mechanicName: 'Garage El Amel',
      title: 'Knocking noise over bumps, front right',
      car: 'Dacia Duster · 2017',
      category: 'Suspension',
      date: 'Oct 2026',
      problem:
          'A dull knock from the front right corner on rough roads and when turning into a driveway.',
      diagnosis:
          'Worn stabiliser links on both sides and a cracked front strut mount on the right.',
      workDone:
          'Replaced both stabiliser links and the right strut mount, then checked the alignment.',
      laborCost: 5000,
      partsCost: 11500,
      durationHours: 3,
      partsUsed: ['Stabiliser links (x2)', 'Front strut mount'],
      warrantyMonths: 6,
      helpful: 9,
    ),
    RepairReport(
      id: 'r5',
      mechanicId: 'm3',
      mechanicName: 'Karim B. Auto Service',
      title: 'A/C blows warm air after a few minutes',
      car: 'Hyundai i10 · 2019',
      category: 'Air conditioning',
      date: 'Jul 2026',
      problem:
          'The air conditioning is cold at first, then turns warm within ten minutes of driving.',
      diagnosis:
          'Slow refrigerant leak at the condenser connection. The compressor was working normally.',
      workDone:
          'Replaced the seals, vacuumed the system, recharged it and added leak-detection dye.',
      laborCost: 3500,
      partsCost: 4000,
      durationHours: 1.5,
      partsUsed: [
        'R134a refrigerant',
        'Condenser O-ring kit',
        'UV leak dye',
      ],
      warrantyMonths: 3,
      helpful: 14,
    ),
    RepairReport(
      id: 'r6',
      mechanicId: 'm2',
      mechanicName: 'Atelier Mécanique Nour',
      title: 'Engine overheating in traffic',
      car: 'Renault Symbol · 2014',
      category: 'Engine',
      date: 'Sep 2026',
      problem:
          'Temperature gauge climbs when stuck in traffic and drops again once the car moves.',
      diagnosis:
          'Thermostat stuck closed, and the cooling fan was not starting because of a failed relay.',
      workDone:
          'Replaced the thermostat and fan relay, flushed and refilled the coolant, pressure tested the system.',
      laborCost: 5500,
      partsCost: 9500,
      durationHours: 4,
      partsUsed: ['Thermostat', 'Cooling fan relay', 'Coolant (5 L)'],
      warrantyMonths: 6,
      helpful: 19,
    ),
    RepairReport(
      id: 'r7',
      mechanicId: 'm4',
      mechanicName: 'Auto Diagnostic Plus',
      title: 'Check engine light and rough idle',
      car: 'Peugeot 308 · 2017',
      category: 'Diagnostics',
      date: 'Oct 2026',
      problem:
          'Orange engine warning light, shaking at idle and a loss of power when accelerating.',
      diagnosis:
          'OBD scan showed a misfire on cylinder 3 (P0303). The ignition coil was failing and the plugs were worn.',
      workDone:
          'Replaced the coil and all four spark plugs, cleared the fault and road tested.',
      laborCost: 3000,
      partsCost: 6500,
      durationHours: 2,
      partsUsed: ['Ignition coil', 'Spark plugs (x4)'],
      warrantyMonths: 3,
      helpful: 21,
    ),
    RepairReport(
      id: 'r8',
      mechanicId: 'm4',
      mechanicName: 'Auto Diagnostic Plus',
      title: 'Windows and central locking stop working randomly',
      car: 'VW Polo · 2015',
      category: 'Electrical',
      date: 'Aug 2026',
      problem:
          'Driver window and central locking work some days and not others.',
      diagnosis:
          'Broken wires inside the driver door rubber boot from repeated flexing.',
      workDone:
          'Repaired the wires, fitted a new protective sleeve and tested every door function.',
      laborCost: 4000,
      partsCost: 3500,
      durationHours: 2.5,
      partsUsed: ['Door wiring sleeve', 'Connector pins'],
      warrantyMonths: 3,
      helpful: 8,
    ),
    RepairReport(
      id: 'r9',
      mechanicId: 'm5',
      mechanicName: 'Mécanique Générale Rachid',
      title: 'Grinding when shifting into second gear',
      car: 'Dacia Logan · 2013',
      category: 'Gearbox',
      date: 'Jun 2026',
      problem: 'Crunching noise when selecting second gear, mostly when cold.',
      diagnosis:
          'Low and degraded gearbox oil, and the shift cable was out of adjustment.',
      workDone:
          'Changed the gearbox oil, adjusted the cable and linkage, then road tested.',
      laborCost: 3500,
      partsCost: 2500,
      durationHours: 1.5,
      partsUsed: ['Gearbox oil (2 L)'],
      warrantyMonths: 1,
      helpful: 6,
    ),
  ];

  /// Appointment requests sent by the demo client.
  final List<AppointmentRequest> appointments = [];

  final Set<String> _helpfulIds = {};

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

  static List<String> _tokens(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  Mechanic mechanicById(String id) => mechanics.firstWhere((m) => m.id == id);

  int reportsCountFor(String mechanicId) =>
      reports.where((r) => r.mechanicId == mechanicId).length;

  List<RepairReport> reportsForMechanic(String mechanicId) =>
      reports.where((r) => r.mechanicId == mechanicId).toList();

  List<Mechanic> searchMechanics({
    String query = '',
    String? category,
    bool verifiedOnly = false,
    bool openNowOnly = false,
    MechanicSort sort = MechanicSort.topRated,
  }) {
    final tokens = _tokens(query);
    final list = mechanics.where((m) {
      if (category != null && !m.specialties.contains(category)) return false;
      if (verifiedOnly && !m.verified) return false;
      if (openNowOnly && !m.openNow) return false;
      if (tokens.isEmpty) return true;
      final hay = '${m.name} ${m.specialties.join(' ')} ${m.address} '
              '${m.services.map((s) => s.name).join(' ')}'
          .toLowerCase();
      return tokens.every((t) => hay.contains(t));
    }).toList();
    switch (sort) {
      case MechanicSort.topRated:
        list.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : b.reviews.compareTo(a.reviews);
        });
      case MechanicSort.nearest:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case MechanicSort.mostReports:
        list.sort(
          (a, b) => reportsCountFor(b.id).compareTo(reportsCountFor(a.id)),
        );
    }
    return list;
  }

  List<RepairReport> searchReports(
    String query, {
    String? category,
    ReportSort sort = ReportSort.mostHelpful,
  }) {
    final tokens = _tokens(query);
    final list = reports.where((r) {
      if (category != null && r.category != category) return false;
      if (tokens.isEmpty) return true;
      final hay = '${r.title} ${r.car} ${r.category} ${r.mechanicName} '
              '${r.problem} ${r.diagnosis} ${r.workDone} '
              '${r.partsUsed.join(' ')}'
          .toLowerCase();
      return tokens.every((t) => hay.contains(t));
    }).toList();
    switch (sort) {
      case ReportSort.mostHelpful:
        list.sort((a, b) => helpfulCountFor(b).compareTo(helpfulCountFor(a)));
      case ReportSort.lowestCost:
        list.sort((a, b) => a.cost.compareTo(b.cost));
      case ReportSort.fastest:
        list.sort((a, b) => a.durationHours.compareTo(b.durationHours));
    }
    return list;
  }

  bool isHelpful(String reportId) => _helpfulIds.contains(reportId);

  int helpfulCountFor(RepairReport r) =>
      r.helpful + (_helpfulIds.contains(r.id) ? 1 : 0);

  void toggleHelpful(String reportId) {
    if (!_helpfulIds.add(reportId)) _helpfulIds.remove(reportId);
    notifyListeners();
  }

  AppointmentRequest requestAppointment({
    required Mechanic mechanic,
    required String service,
    required DateTime when,
    String note = '',
  }) {
    final request = AppointmentRequest(
      mechanic: mechanic,
      service: service,
      when: when,
      note: note,
    );
    appointments.insert(0, request);
    notifyListeners();
    return request;
  }

  void cancelAppointment(AppointmentRequest request) {
    request.status = 'Cancelled';
    notifyListeners();
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
