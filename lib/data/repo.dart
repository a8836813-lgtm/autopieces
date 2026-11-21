import 'package:flutter/foundation.dart';

import '../models/search_query.dart';
import 'models.dart';
import 'vehicles.dart';

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

  late final List<Reservation> reservations = _seedReservations();

  List<Reservation> _seedReservations() {
    SearchResult? at(String partId) {
      final item = stockFor(myShopId, partId);
      if (item == null) return null;
      return SearchResult(
        part: partById(partId),
        shop: shopById(myShopId),
        stock: item,
      );
    }

    final now = DateTime.now();
    final list = <Reservation>[];
    void add(String partId, String client, String status, Duration ago) {
      final r = at(partId);
      if (r == null) return;
      list.add(Reservation(
        item: r,
        clientName: client,
        status: status,
        createdAt: now.subtract(ago),
      ));
    }

    add('p1', 'Rachid M.', 'Pending', const Duration(minutes: 25));
    add('p3', 'Souad B.', 'Pending', const Duration(hours: 2));
    add('p8', 'Walid H.', 'Confirmed', const Duration(hours: 5));
    return list;
  }

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

  final List<RepairReport> reports = [
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
      cost: 24000,
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
      cost: 19500,
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
      cost: 9000,
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
      cost: 16500,
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
      cost: 7500,
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
      cost: 15000,
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
      cost: 9500,
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
      cost: 7500,
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
      cost: 6000,
      durationHours: 1.5,
      partsUsed: ['Gearbox oil (2 L)'],
      warrantyMonths: 1,
      helpful: 6,
    ),
  ];

  /// Appointment requests sent by the demo client.
  final List<AppointmentRequest> appointments = [];

  // ------------------------------------------------------------- shop mode

  /// Settings of the logged-in shop (the const [Shop] list cannot change).
  bool shopOpen = true;
  String shopHours = 'Open until 19:00';
  String shopPhone = '';
  String shopAbout = 'Brake parts, filters and batteries for most cars.';
  bool shopDelivers = false;
  final Set<String> shopPayments = {'Cash'};

  /// A part counts as "low" when its quantity is at or under this number.
  int lowStockLimit = 1;

  final List<Sale> sales = _seedSales();
  final List<ActivityEntry> activity = [];

  /// Replies the shop owner wrote to reviews (key: [reviewKey]).
  final Map<String, String> reviewReplies = {};

  static List<Sale> _seedSales() {
    final now = DateTime.now();
    DateTime ago(int days, int hour) =>
        DateTime(now.year, now.month, now.day - days, hour);
    return [
      Sale(partName: 'Brake pads (front)', quantity: 2, amount: 15800, date: ago(0, 10)),
      Sale(partName: 'Engine oil filter', quantity: 3, amount: 11700, date: ago(1, 11)),
      Sale(partName: 'Spark plug', quantity: 4, amount: 3600, date: ago(1, 15)),
      Sale(partName: 'Brake discs (pair)', quantity: 1, amount: 6300, date: ago(2, 9)),
      Sale(partName: 'Brake pads (front)', quantity: 1, amount: 7900, date: ago(3, 16)),
      Sale(partName: 'Engine oil filter', quantity: 2, amount: 7800, date: ago(4, 12)),
      Sale(partName: 'Spark plug', quantity: 8, amount: 7200, date: ago(5, 10)),
      Sale(partName: 'Brake pads (front)', quantity: 3, amount: 23700, date: ago(6, 14)),
      Sale(partName: 'Brake discs (pair)', quantity: 2, amount: 12600, date: ago(8, 11)),
      Sale(partName: 'Engine oil filter', quantity: 5, amount: 19500, date: ago(10, 9)),
      Sale(partName: 'Spark plug', quantity: 6, amount: 5400, date: ago(12, 13)),
    ];
  }

  /// Mechanic mode: jobs asked of the logged-in mechanic.
  final List<JobRequest> jobs = _seedJobs();

  /// Mechanic mode: "available now" switch and the demo Pro plan.
  bool mechanicAvailable = true;
  bool mechanicPro = false;

  static List<JobRequest> _seedJobs() {
    final now = DateTime.now();
    DateTime day(int daysAgo, int hour) =>
        DateTime(now.year, now.month, now.day - daysAgo, hour);
    return [
      JobRequest(
        id: 'j1',
        clientName: 'Samira L.',
        car: 'Renault Clio 4 (2017)',
        problem: 'Brakes squeal and the pedal feels soft',
        distanceKm: 3.4,
        price: 6000,
        slot: now.add(const Duration(hours: 3)),
        urgent: true,
      ),
      JobRequest(
        id: 'j2',
        clientName: 'Karim B.',
        car: 'Peugeot 208 (2018)',
        problem: 'Engine light on and rough idle',
        distanceKm: 2.1,
        price: 4500,
        slot: day(-1, 10),
      ),
      JobRequest(
        id: 'j3',
        clientName: 'Yacine M.',
        car: 'Dacia Logan (2015)',
        problem: 'Oil and filter change',
        distanceKm: 1.2,
        price: 3000,
        slot: day(-1, 14),
        status: 'Accepted',
      ),
      JobRequest(
        id: 'j4',
        clientName: 'Nadia H.',
        car: 'Hyundai i10 (2019)',
        problem: 'Air conditioning does not cool',
        distanceKm: 4.8,
        price: 8000,
        slot: now.subtract(const Duration(hours: 1)),
        status: 'In progress',
      ),
      JobRequest(
        id: 'j5',
        clientName: 'Omar T.',
        car: 'Toyota Hilux (2014)',
        problem: 'Timing belt replacement',
        distanceKm: 6.0,
        price: 22000,
        slot: day(1, 9),
        status: 'Done',
        completedAt: day(1, 16),
      ),
      JobRequest(
        id: 'j6',
        clientName: 'Lina S.',
        car: 'Kia Picanto (2020)',
        problem: 'Battery replacement',
        distanceKm: 2.7,
        price: 9500,
        slot: day(2, 11),
        status: 'Done',
        completedAt: day(2, 12),
      ),
      JobRequest(
        id: 'j7',
        clientName: 'Amine R.',
        car: 'VW Golf 7 (2016)',
        problem: 'Front suspension noise',
        distanceKm: 3.9,
        price: 12000,
        slot: day(4, 9),
        status: 'Done',
        completedAt: day(4, 15),
      ),
      JobRequest(
        id: 'j8',
        clientName: 'Sofiane K.',
        car: 'Renault Symbol (2013)',
        problem: 'Clutch kit replacement',
        distanceKm: 5.2,
        price: 15000,
        slot: day(6, 9),
        status: 'Done',
        completedAt: day(6, 17),
      ),
      JobRequest(
        id: 'j9',
        clientName: 'Meriem D.',
        car: 'Fiat Tipo (2018)',
        problem: 'Alternator replacement',
        distanceKm: 1.8,
        price: 13000,
        slot: day(9, 9),
        status: 'Done',
        completedAt: day(9, 14),
      ),
      JobRequest(
        id: 'j10',
        clientName: 'Hichem A.',
        car: 'Skoda Octavia (2012)',
        problem: 'Brake discs and pads',
        distanceKm: 4.1,
        price: 11000,
        slot: day(11, 9),
        status: 'Done',
        completedAt: day(11, 13),
      ),
    ];
  }

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

  static List<String> _tokens(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  Mechanic mechanicById(String id) => mechanics.firstWhere((m) => m.id == id);

  int reportsCountFor(String mechanicId) =>
      reportsOf(mechanicById(mechanicId).name).length;

  List<RepairReport> reportsForMechanic(String mechanicId) =>
      reportsOf(mechanicById(mechanicId).name);

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
      if (openNowOnly && !isMechanicOpen(m)) return false;
      if (tokens.isEmpty) return true;
      final hay = '${m.name} ${m.specialties.join(' ')} ${m.address} '
              '${m.services.map((s) => s.name).join(' ')}'
          .toLowerCase();
      return tokens.every((t) => hay.contains(t));
    }).toList();
    switch (sort) {
      case MechanicSort.topRated:
        double stars(Mechanic m) => averageStars(m.id) ?? m.rating;
        list.sort((a, b) {
          final byRating = stars(b).compareTo(stars(a));
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
              '${r.parts} ${r.partsUsed.join(' ')}'
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

  bool isHelpful(String reportKey) => _helpfulIds.contains(reportKey);

  int helpfulCountFor(RepairReport r) =>
      r.helpful + (_helpfulIds.contains(r.key) ? 1 : 0);

  void toggleHelpful(String reportKey) {
    if (!_helpfulIds.add(reportKey)) _helpfulIds.remove(reportKey);
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
    if (shopId == myShopId) {
      logActivity(existing == null
          ? 'Added ${partById(partId).name} to stock ($quantity units)'
          : 'Updated ${partById(partId).name}: $quantity units, $price DZD');
    }
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
    logActivity('Confirmed ${reservation.item.part.name} for ${reservation.clientName}');
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
    r.completedAt = DateTime.now();
    final item = r.item.stock;
    if (item.quantity > 0) item.quantity--;
    if (r.item.shop.id == myShopId) {
      sales.insert(
        0,
        Sale(
          partName: r.item.part.name,
          quantity: 1,
          amount: item.price,
          date: r.completedAt!,
        ),
      );
      logActivity('${r.clientName} picked up ${r.item.part.name} (${item.price} DZD)');
    }
    notifyListeners();
  }

  void markReviewed(Reservation r) {
    r.reviewed = true;
    notifyListeners();
  }

  /// Reservations made by the demo client (the other ones belong to shop
  /// customers and only show in shop mode).
  List<Reservation> get clientReservations =>
      reservations.where((r) => r.clientName == 'Client (demo)').toList();

  /// Reviews are only allowed for completed reservations.
  Reservation? reviewableReservationAt(String shopId) {
    for (final r in clientReservations) {
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

  // ------------------------------------------------------- shop owner tools

  void logActivity(String text) {
    activity.insert(0, ActivityEntry(text));
    if (activity.length > 30) activity.removeLast();
  }

  bool isShopOpen(Shop s) => s.id == myShopId ? shopOpen : s.openNow;

  String shopHoursOf(Shop s) => s.id == myShopId ? shopHours : s.hours;

  String shopPhoneOf(Shop s) =>
      s.id == myShopId && shopPhone.trim().isNotEmpty ? shopPhone : s.phone;

  void setShopOpen(bool value) {
    shopOpen = value;
    logActivity(value ? 'Shop set to open' : 'Shop set to closed');
    notifyListeners();
  }

  void updateShopInfo({
    required String hours,
    required String phone,
    required String about,
    required bool delivers,
    required Set<String> payments,
  }) {
    shopHours = hours.trim().isEmpty ? shopHours : hours.trim();
    shopPhone = phone.trim();
    shopAbout = about.trim();
    shopDelivers = delivers;
    shopPayments
      ..clear()
      ..addAll(payments);
    logActivity('Shop information updated');
    notifyListeners();
  }

  void setLowStockLimit(int value) {
    lowStockLimit = value.clamp(0, 20);
    notifyListeners();
  }

  /// Adds [delta] units (can be negative) to a stock item, never below 0.
  void adjustStock(StockItem item, int delta) {
    final next = item.quantity + delta;
    item.quantity = next < 0 ? 0 : next;
    logActivity(
      '${partById(item.partId).name}: ${delta >= 0 ? '+' : ''}$delta, now ${item.quantity} units',
    );
    notifyListeners();
  }

  void removeStock(StockItem item) {
    final name = partById(item.partId).name;
    stock.remove(item);
    logActivity('Removed $name from stock');
    notifyListeners();
  }

  /// Raises or lowers prices of the shop stock by [percent]. When [category]
  /// is null every part changes. Returns how many items changed.
  int bulkPriceChange({String? category, required double percent}) {
    var changed = 0;
    for (final item in stockOfShop(myShopId)) {
      if (category != null && partById(item.partId).category != category) {
        continue;
      }
      final next = (item.price * (1 + percent / 100)).round();
      item.price = next < 1 ? 1 : next;
      changed++;
    }
    if (changed > 0) {
      logActivity(
        'Prices ${percent >= 0 ? 'raised' : 'lowered'} ${percent.abs().toStringAsFixed(0)}% '
        '(${category ?? 'all parts'}, $changed items)',
      );
      notifyListeners();
    }
    return changed;
  }

  /// The shop turns down a pending or confirmed reservation.
  void declineReservation(Reservation r) {
    if (!r.isActive) return;
    r.status = 'Cancelled';
    logActivity('Declined ${r.item.part.name} for ${r.clientName}');
    notifyListeners();
  }

  List<Reservation> shopReservations() =>
      reservations.where((r) => r.item.shop.id == myShopId).toList();

  int get pendingOrdersCount =>
      shopReservations().where((r) => r.status == 'Pending').length;

  List<StockItem> get outOfStockItems =>
      stockOfShop(myShopId).where((s) => s.quantity <= 0).toList();

  List<StockItem> get lowStockItems => stockOfShop(myShopId)
      .where((s) => s.quantity > 0 && s.quantity <= lowStockLimit)
      .toList();

  /// Total value of the stock at selling price, in DZD.
  int get stockValue =>
      stockOfShop(myShopId).fold(0, (a, s) => a + s.price * s.quantity);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Sales per day for the last 7 days (oldest first, today last).
  List<int> weeklySales() {
    final today = _day(DateTime.now());
    final result = List<int>.filled(7, 0);
    for (final s in sales) {
      final ago = today.difference(_day(s.date)).inDays;
      if (ago >= 0 && ago < 7) result[6 - ago] += s.amount;
    }
    return result;
  }

  int get weekSales => weeklySales().fold(0, (a, b) => a + b);

  int get lastWeekSales {
    final today = _day(DateTime.now());
    var total = 0;
    for (final s in sales) {
      final ago = today.difference(_day(s.date)).inDays;
      if (ago >= 7 && ago < 14) total += s.amount;
    }
    return total;
  }

  int get todaySales {
    final today = _day(DateTime.now());
    return sales
        .where((s) => _day(s.date) == today)
        .fold(0, (a, s) => a + s.amount);
  }

  /// Best sellers over all recorded sales: part name to units sold.
  List<MapEntry<String, int>> topSelling({int limit = 5}) {
    final units = <String, int>{};
    for (final s in sales) {
      units[s.partName] = (units[s.partName] ?? 0) + s.quantity;
    }
    final list = units.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  static String reviewKey(Review r) =>
      '${r.targetId}|${r.author}|${r.createdAt.millisecondsSinceEpoch}';

  String? replyTo(Review r) => reviewReplies[reviewKey(r)];

  void setReviewReply(Review r, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      reviewReplies.remove(reviewKey(r));
    } else {
      reviewReplies[reviewKey(r)] = trimmed;
      logActivity('Replied to ${r.author}');
    }
    notifyListeners();
  }

  // ------------------------------------------------------- mechanic mode

  void deleteReport(RepairReport report) {
    reports.remove(report);
    notifyListeners();
  }

  void setMechanicAvailable(bool value) {
    mechanicAvailable = value;
    notifyListeners();
  }

  void setMechanicPro(bool value) {
    mechanicPro = value;
    notifyListeners();
  }

  /// Open now, taking the logged-in mechanic's own switch into account.
  bool isMechanicOpen(Mechanic m) =>
      m.id == myMechanicId ? mechanicAvailable : m.openNow;

  /// Featured on the client side, also when the demo Pro plan is on.
  bool isMechanicFeatured(Mechanic m) =>
      m.premium || (m.id == myMechanicId && mechanicPro);

  void acceptJob(JobRequest job) {
    job.status = 'Accepted';
    notifyListeners();
  }

  void declineJob(JobRequest job) {
    job.status = 'Declined';
    notifyListeners();
  }

  void startJob(JobRequest job) {
    job.status = 'In progress';
    notifyListeners();
  }

  void finishJob(JobRequest job) {
    job.status = 'Done';
    job.completedAt = DateTime.now();
    notifyListeners();
  }

  List<JobRequest> jobsWithStatus(Set<String> statuses) {
    final list = jobs.where((j) => statuses.contains(j.status)).toList();
    list.sort((a, b) => a.slot.compareTo(b.slot));
    return list;
  }

  int get jobsDoneCount => jobs.where((j) => j.status == 'Done').length;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Money earned per day for the last 7 days (oldest first, today last).
  List<int> weeklyEarnings() {
    final today = _dayOf(DateTime.now());
    final result = List<int>.filled(7, 0);
    for (final j in jobs) {
      final done = j.completedAt;
      if (j.status != 'Done' || done == null) continue;
      final ago = today.difference(_dayOf(done)).inDays;
      if (ago >= 0 && ago < 7) result[6 - ago] += j.price;
    }
    return result;
  }

  int get weekEarnings => weeklyEarnings().fold(0, (a, b) => a + b);

  int get lastWeekEarnings {
    final today = _dayOf(DateTime.now());
    var total = 0;
    for (final j in jobs) {
      final done = j.completedAt;
      if (j.status != 'Done' || done == null) continue;
      final ago = today.difference(_dayOf(done)).inDays;
      if (ago >= 7 && ago < 14) total += j.price;
    }
    return total;
  }

  /// Share of requests the mechanic answered (accepted or declined), 0 to 1.
  double get responseRate {
    if (jobs.isEmpty) return 0;
    final answered = jobs.where((j) => j.status != 'New').length;
    return answered / jobs.length;
  }

  /// Share of accepted jobs that were finished, 0 to 1.
  double get completionRate {
    final accepted = jobs.where((j) => j.status != 'New' && j.status != 'Declined');
    if (accepted.isEmpty) return 0;
    final done = accepted.where((j) => j.status == 'Done').length;
    return done / accepted.length;
  }

  /// Experience points: reports, finished jobs and reviews all count.
  int get mechanicXp =>
      reportsOf(myMechanicName).length * 30 +
      jobsDoneCount * 20 +
      reviewsFor(myMechanicId).length * 10;

  List<MechanicBadge> mechanicBadges() {
    final reportCount = reportsOf(myMechanicName).length;
    final avg = averageStars(myMechanicId) ?? 0;
    final fiveStar = reviewsFor(myMechanicId).any((r) => r.stars == 5);
    return [
      MechanicBadge(
        id: 'first',
        title: 'First report',
        hint: 'Publish 1 repair report',
        earned: reportCount >= 1,
      ),
      MechanicBadge(
        id: 'story',
        title: 'Storyteller',
        hint: 'Publish 3 repair reports',
        earned: reportCount >= 3,
      ),
      MechanicBadge(
        id: 'top',
        title: 'Top rated',
        hint: 'Keep an average of 4.5 stars',
        earned: avg >= 4.5,
      ),
      MechanicBadge(
        id: 'five',
        title: '5-star review',
        hint: 'Get a 5-star review',
        earned: fiveStar,
      ),
      MechanicBadge(
        id: 'trusted',
        title: 'Trusted',
        hint: 'Finish 3 jobs',
        earned: jobsDoneCount >= 3,
      ),
      MechanicBadge(
        id: 'pro',
        title: 'Pro member',
        hint: 'Switch on the Pro plan',
        earned: mechanicPro,
      ),
    ];
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
