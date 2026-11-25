import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/notifier.dart';
import 'models.dart';
import 'repo.dart';

class RemoteSync {
  RemoteSync._();

  static final ApiClient _api = ApiClient.instance;
  static const double _refLat = 36.8200;
  static const double _refLng = 5.7667;
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static Timer? _timer;
  static AppUser? _user;
  static int _pending = 0;
  static bool _loading = false;

  static String _s(dynamic v) => v == null ? '' : '$v';
  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static bool _b(dynamic v) => v == true || v == 1 || v == '1';
  static DateTime _t(dynamic v) =>
      DateTime.tryParse(_s(v).replaceFirst(' ', 'T')) ?? DateTime.now();
  static DateTime? _tn(dynamic v) => v == null ? null : _t(v);
  static List<Map<String, dynamic>> _list(dynamic v) =>
      ((v as List?) ?? const []).whereType<Map<String, dynamic>>().toList();
  static List<String> _csv(dynamic v) => _s(v)
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static double _km(double lat, double lng) {
    const r = 6371.0;
    double rad(double x) => x * math.pi / 180;
    final dLat = rad(lat - _refLat);
    final dLng = rad(lng - _refLng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(_refLat)) *
            math.cos(rad(lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _bearing(double lat, double lng) {
    double rad(double x) => x * math.pi / 180;
    final y = math.sin(rad(lng - _refLng)) * math.cos(rad(lat));
    final x = math.cos(rad(_refLat)) * math.sin(rad(lat)) -
        math.sin(rad(_refLat)) * math.cos(rad(lat)) * math.cos(rad(lng - _refLng));
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static String _monthYear(dynamic v) {
    final t = _t(v);
    return '${_months[t.month - 1]} ${t.year}';
  }

  static bool isServerId(String id) => int.tryParse(id) != null;

  static Future<void> load(Repo repo, AppUser user) async {
    _user = user;
    await _fill(repo, user);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => refresh(repo));
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _user = null;
    _pending = 0;
  }

  static Future<void> refresh(Repo repo) async {
    final user = _user;
    if (user == null || _pending > 0 || _loading) return;
    try {
      await _fill(repo, user);
    } catch (_) {}
  }

  static void push(
    Repo repo,
    Future<void> Function() call, {
    bool reload = false,
  }) {
    _run(repo, call, reload);
  }

  static Future<void> _run(
    Repo repo,
    Future<void> Function() call,
    bool reload,
  ) async {
    _pending++;
    var failed = false;
    try {
      await call();
    } catch (e) {
      failed = true;
      showSnack(e is ApiException ? e.message : 'Could not save the change.');
    } finally {
      _pending--;
    }
    if (failed || reload) await _forceRefresh(repo);
  }

  static Future<void> _forceRefresh(Repo repo) async {
    final user = _user;
    if (user == null || _pending > 0) return;
    try {
      await _fill(repo, user);
    } catch (_) {}
  }

  static Future<void> _fill(Repo repo, AppUser user) async {
    _loading = true;
    try {
      final isClient = user.role == UserRole.client;
      final isShop = user.role == UserRole.shop;
      final isMechanic = user.role == UserRole.mechanic;

      final results = await Future.wait<Map<String, dynamic>>([
        _api.get(ApiEndpoints.shops),
        _api.get(ApiEndpoints.parts),
        _api.get(ApiEndpoints.stock, {'all': '1'}),
        _api.get(ApiEndpoints.mechanics),
        _api.get(ApiEndpoints.reports),
        _api.get(ApiEndpoints.reviews, {'all': '1'}),
        if (isClient) _api.get(ApiEndpoints.reservations),
        if (isClient) _api.get(ApiEndpoints.appointments),
        if (isClient) _api.get(ApiEndpoints.favorites),
        if (isClient) _api.get(ApiEndpoints.priceAlerts),
        if (isShop) _api.get(ApiEndpoints.reservations, {'as': 'shop'}),
        if (isShop) _api.get(ApiEndpoints.myShop),
        if (isMechanic) _api.get(ApiEndpoints.jobs),
      ]);

      Repo.myShopId = user.shopId ?? '';
      Repo.myMechanicId = user.mechanicId ?? '';

      repo.shops
        ..clear()
        ..addAll(_list(results[0]['shops']).map(_shop));
      repo.parts
        ..clear()
        ..addAll(_list(results[1]['parts']).map(_part));
      repo.stock
        ..clear()
        ..addAll(_list(results[2]['stock']).map(_stock));
      repo.mechanics
        ..clear()
        ..addAll(_list(results[3]['mechanics']).map(_mechanic));

      final mine = repo.mechanics.where((m) => m.id == Repo.myMechanicId);
      Repo.myMechanicName = mine.isEmpty ? user.name : mine.first.name;

      repo.helpfulIds.clear();
      repo.reports
        ..clear()
        ..addAll(_list(results[4]['reports']).map((r) {
          if (_b(r['voted'])) repo.helpfulIds.add(_s(r['id']));
          return _report(r);
        }));

      repo.reviews.clear();
      repo.reviewReplies.clear();
      for (final r in _list(results[5]['reviews'])) {
        final review = Review(
          id: _s(r['id']),
          targetId: _s(r['target_id']),
          author: _s(r['author_name']),
          stars: _i(r['stars']),
          comment: _s(r['comment']),
          createdAt: _t(r['created_at']),
          photos: [for (final p in (r['photos'] as List? ?? const [])) ApiClient.absolute('$p')],
        );
        repo.reviews.add(review);
        final reply = _s(r['reply']);
        if (reply.isNotEmpty) repo.reviewReplies[Repo.reviewKey(review)] = reply;
      }

      repo.reservations.clear();
      repo.appointments.clear();
      repo.jobs.clear();
      repo.sales.clear();
      repo.favoriteShopIds.clear();
      repo.favoritePartIds.clear();
      repo.priceAlerts.clear();

      var next = 6;
      if (isClient) {
        for (final r in _list(results[next++]['reservations'])) {
          final res = _reservation(repo, r, mine: true);
          if (res != null) repo.reservations.add(res);
        }
        for (final a in _list(results[next++]['appointments'])) {
          final ap = _appointment(repo, a);
          if (ap != null) repo.appointments.add(ap);
        }
        final fav = results[next++];
        repo.favoriteShopIds.addAll((fav['shops'] as List).map((e) => '$e'));
        repo.favoritePartIds.addAll((fav['parts'] as List).map((e) => '$e'));
        for (final a in _list(results[next++]['alerts'])) {
          repo.priceAlerts.add(PriceAlert(
            partId: _s(a['part_id']),
            targetPrice: _i(a['target_price']),
            createdAt: _t(a['created_at']),
          ));
        }
      }
      if (isShop) {
        for (final r in _list(results[next++]['reservations'])) {
          final res = _reservation(repo, r, mine: false);
          if (res == null) continue;
          repo.reservations.add(res);
          if (res.status == 'Completed' && res.completedAt != null) {
            repo.sales.add(Sale(
              partName: res.item.part.name,
              quantity: 1,
              amount: _i(r['price']),
              date: res.completedAt!,
            ));
          }
        }
        final shop = results[next++]['shop'] as Map<String, dynamic>;
        repo.shopOpen = _b(shop['open_now']);
        repo.shopHours = _s(shop['hours']);
        repo.shopPhone = _s(shop['phone']);
        repo.shopAbout = _s(shop['about']);
        repo.shopDelivers = _b(shop['delivers']);
        repo.lowStockLimit = _i(shop['low_stock_limit']);
      }
      if (isMechanic) {
        for (final j in _list(results[next++]['jobs'])) {
          repo.jobs.add(_job(j));
        }
        repo.mechanicAvailable =
            mine.isEmpty ? true : mine.first.openNow;
      }
      repo.touch();
    } finally {
      _loading = false;
    }
  }

  static Shop _shop(Map<String, dynamic> m) {
    final hasPos = m['lat'] != null && m['lng'] != null;
    final lat = _d(m['lat']);
    final lng = _d(m['lng']);
    return Shop(
      id: _s(m['id']),
      name: _s(m['name']),
      type: _s(m['type']),
      distanceKm: hasPos ? _km(lat, lng) : 5,
      rating: _d(m['rating']),
      partsCount: _i(m['parts_count']),
      hours: _s(m['hours']),
      openNow: _b(m['open_now']),
      phone: _s(m['phone']),
      bearing: hasPos ? _bearing(lat, lng) : 0,
    );
  }

  static Part _part(Map<String, dynamic> m) {
    final fitments = <Fitment>[];
    final raw = _s(m['fitments_json']);
    if (raw.isNotEmpty) {
      try {
        for (final f in (jsonDecode(raw) as List).whereType<Map>()) {
          final brand = _s(f['brandId'] ?? f['brand']);
          if (brand.isEmpty) continue;
          final model = _s(f['model']);
          fitments.add(Fitment(brand, model.isEmpty ? null : model));
        }
      } catch (_) {}
    }
    return Part(
      id: _s(m['id']),
      name: _s(m['name']),
      oem: _s(m['oem']),
      category: _s(m['category']),
      fits: _s(m['fits']),
      altSerials: _csv(m['alt_serials']),
      fitments: fitments,
    );
  }

  static StockItem _stock(Map<String, dynamic> m) => StockItem(
        id: _s(m['stock_id']),
        shopId: _s(m['shop_id']),
        partId: _s(m['part_id']),
        quantity: _i(m['quantity']),
        price: _i(m['price']),
        condition: _s(m['part_condition']).isEmpty ? 'New' : _s(m['part_condition']),
      );

  static Mechanic _mechanic(Map<String, dynamic> m) {
    return Mechanic(
      id: _s(m['id']),
      name: _s(m['name']),
      specialties: _csv(m['specialties']),
      rating: _d(m['rating']),
      reviews: _i(m['reviews_count']),
      distanceKm: m['lat'] == null ? 5 : _km(_d(m['lat']), _d(m['lng'])),
      address: _s(m['address']),
      phone: _s(m['phone']),
      hours: _s(m['hours']),
      openNow: _b(m['available']),
      about: _s(m['about']),
      services: [
        for (final s in _list(m['services']))
          MechanicService(_s(s['name']), _i(s['price_from'])),
      ],
      premium: _b(m['premium']),
      verified: _b(m['verified']),
      yearsExperience: _i(m['years_experience']),
      responseTime: _s(m['response_time']),
      languages: _csv(m['languages']),
      mobileService: _b(m['mobile_service']),
    );
  }

  static RepairReport _report(Map<String, dynamic> r) {
    final voted = _b(r['voted']);
    return RepairReport(
      id: _s(r['id']),
      mechanicId: _s(r['mechanic_id']),
      mechanicName: _s(r['mechanic_name']),
      title: _s(r['title']),
      car: _s(r['car']),
      category: _s(r['category']),
      date: _monthYear(r['created_at']),
      problem: _s(r['problem']),
      diagnosis: _s(r['diagnosis']),
      workDone: _s(r['work_done']),
      cost: _i(r['cost']),
      laborCost: _i(r['labour_cost']),
      partsCost: _i(r['parts_cost']),
      durationHours: _d(r['duration_hours']),
      parts: _s(r['parts_text']),
      partsUsed: _csv(r['parts_text']),
      warrantyMonths: _i(r['warranty_months']),
      helpful: _i(r['helpful']) - (voted ? 1 : 0),
    );
  }

  static Reservation? _reservation(Repo repo, Map<String, dynamic> r,
      {required bool mine}) {
    final stockId = _s(r['stock_id']);
    final stock = repo.stock.where((s) => s.id == stockId);
    if (stock.isEmpty) return null;
    final item = stock.first;
    final part = repo.parts.where((p) => p.id == item.partId);
    final shop = repo.shops.where((s) => s.id == item.shopId);
    if (part.isEmpty || shop.isEmpty) return null;
    return Reservation(
      id: _s(r['id']),
      mine: mine,
      item: SearchResult(part: part.first, shop: shop.first, stock: item),
      createdAt: _t(r['created_at']),
      status: _s(r['status']),
      reviewed: _b(r['reviewed']),
      clientName: _s(r['client_name']),
      completedAt: _tn(r['completed_at']),
    );
  }

  static void _applyPhotos(JobRequest job, dynamic photos) {
    job.photos.clear();
    job.photoIds.clear();
    for (final p in (photos as List? ?? const []).whereType<Map>()) {
      final url = ApiClient.absolute('${p['url']}');
      job.photos.add(url);
      job.photoIds[url] = _i(p['id']);
    }
  }

  static JobRequest _job(Map<String, dynamic> j) {
    final job = JobRequest(
      id: _s(j['id']),
      clientName: _s(j['client_name']),
      car: _s(j['car']),
      problem: _s(j['problem']),
      distanceKm: 0,
      price: _i(j['price']),
      slot: _t(j['slot']),
      urgent: _b(j['urgent']),
      status: _s(j['status']),
      completedAt: _tn(j['completed_at']),
      createdAt: _t(j['created_at']),
    );
    job.labourCost = j['labour_cost'] == null ? null : _i(j['labour_cost']);
    job.partsCost = _i(j['parts_cost']);
    job.paid = _b(j['paid']);
    job.paidAt = _tn(j['paid_at']);
    _applyPhotos(job, j['photos']);
    return job;
  }

  static AppointmentRequest? _appointment(Repo repo, Map<String, dynamic> a) {
    final mech = repo.mechanics.where((m) => m.id == _s(a['mechanic_id']));
    if (mech.isEmpty) return null;
    final ap = AppointmentRequest(
      mechanic: mech.first,
      service: _s(a['service']),
      when: _t(a['when_at']),
      note: _s(a['note']),
      createdAt: _t(a['created_at']),
      status: _s(a['appointment_status']),
    )..id = _s(a['id']);
    if (a['job_id'] != null) {
      final job = JobRequest(
        id: _s(a['job_id']),
        clientName: '',
        car: '',
        problem: _s(a['service']),
        distanceKm: 0,
        price: 0,
        slot: _t(a['when_at']),
        status: _s(a['job_status']),
      );
      job.labourCost = a['labour_cost'] == null ? null : _i(a['labour_cost']);
      job.partsCost = _i(a['parts_cost']);
      job.paid = _b(a['paid']);
      job.paidAt = _tn(a['paid_at']);
      _applyPhotos(job, a['photos']);
      ap.job = job;
    }
    return ap;
  }

  static Future<void> reserve(Repo repo, SearchResult result) async {
    await _api.post(ApiEndpoints.reservations,
        {'action': 'create', 'stock_id': int.parse(result.stock.id)});
  }

  static Future<void> reservationAction(String action, Reservation r) =>
      _api.post(ApiEndpoints.reservations,
          {'action': action, 'id': int.parse(r.id)});

  static Future<void> toggleFavorite(String kind, String id) => _api.post(
      ApiEndpoints.favorites, {'kind': kind, 'target_id': int.parse(id)});

  static Future<void> setAlert(String partId, int price) => _api.post(
      ApiEndpoints.priceAlerts,
      {'action': 'set', 'part_id': int.parse(partId), 'target_price': price});

  static Future<void> removeAlert(String partId) => _api.post(
      ApiEndpoints.priceAlerts,
      {'action': 'delete', 'part_id': int.parse(partId)});

  static Future<void> toggleHelpful(String reportId) => _api.post(
      ApiEndpoints.reports, {'action': 'helpful', 'id': int.parse(reportId)});

  static Future<void> createAppointment(AppointmentRequest a) => _api.post(
        ApiEndpoints.appointments,
        {
          'action': 'create',
          'mechanic_id': int.parse(a.mechanic.id),
          'service': a.service,
          'when': a.when.toIso8601String(),
          'note': a.note,
        },
      );

  static Future<void> cancelAppointment(AppointmentRequest a) => _api.post(
      ApiEndpoints.appointments, {'action': 'cancel', 'id': int.parse(a.id)});

  static Future<void> upsertStock(Repo repo, StockItem item) async {
    final part = repo.partById(item.partId);
    if (isServerId(part.id)) {
      await _api.post(ApiEndpoints.stock, {
        'action': 'upsert',
        'part_id': int.parse(part.id),
        'price': item.price,
        'quantity': item.quantity,
        'condition': item.condition,
      });
      return;
    }
    final oem = part.oem == 'not set' || part.oem.isEmpty
        ? 'AI-${part.id.replaceFirst('ai_', '').toUpperCase()}'
        : part.oem;
    await _api.post(ApiEndpoints.parts, {
      'name': part.name,
      'oem': oem,
      'category': part.category,
      'fits': part.fits,
      'fitments': [
        for (final f in part.fitments)
          {'brandId': f.brandId, 'model': f.model},
      ],
      'price': item.price,
      'quantity': item.quantity,
      'condition': item.condition,
    });
  }

  static Future<void> adjustStock(Repo repo, StockItem item, int delta) async {
    if (!isServerId(item.partId)) return;
    await _api.post(ApiEndpoints.stock, {
      'action': 'adjust',
      'part_id': int.parse(item.partId),
      'delta': delta,
    });
  }

  static Future<void> removeStock(StockItem item) async {
    if (!isServerId(item.partId)) return;
    await _api.post(ApiEndpoints.stock,
        {'action': 'delete', 'part_id': int.parse(item.partId)});
  }

  static Future<void> bulkPrice(String? category, double percent) =>
      _api.post(ApiEndpoints.stock, {
        'action': 'bulk_price',
        'percent': percent,
        if (category != null) 'category': category,
      });

  static Future<void> saveShop(Map<String, dynamic> fields) =>
      _api.post(ApiEndpoints.myShop, fields);

  static Future<void> addReview(
    Repo repo, {
    required String targetId,
    required int stars,
    required String comment,
    required List<String> photos,
    Reservation? reservation,
  }) {
    final isShop = repo.shops.any((s) => s.id == targetId);
    return _api.postForm(
      ApiEndpoints.reviews,
      {
        'target_kind': isShop ? 'shop' : 'mechanic',
        'target_id': targetId,
        'stars': '$stars',
        'comment': comment,
        if (reservation != null) 'reservation_id': reservation.id,
      },
      files: [for (final p in photos) ApiFile('photos[]', p)],
    );
  }

  static Future<void> replyToReview(Review r, String text) => _api.post(
      ApiEndpoints.reviews,
      {'action': 'reply', 'review_id': int.parse(r.id), 'reply': text});

  static Map<String, dynamic> _reportBody(RepairReport r) => {
        'car': r.car,
        'category': r.category,
        'title': r.title,
        'problem': r.problem,
        'diagnosis': r.diagnosis,
        'work_done': r.workDone,
        'parts_text': r.parts,
        'cost': r.cost,
        'labour_cost': r.laborCost,
        'parts_cost': r.partsCost,
        'duration_hours': r.durationHours,
        'warranty_months': r.warrantyMonths,
      };

  static Future<void> createReport(RepairReport r) =>
      _api.post(ApiEndpoints.reports, {'action': 'create', ..._reportBody(r)});

  static Future<void> updateReport(RepairReport r) => _api.post(
      ApiEndpoints.reports,
      {'action': 'update', 'id': int.parse(r.id), ..._reportBody(r)});

  static Future<void> deleteReport(RepairReport r) => _api.post(
      ApiEndpoints.reports, {'action': 'delete', 'id': int.parse(r.id)});

  static Future<void> setMechanicAvailable(bool value) =>
      _api.post(ApiEndpoints.mechanics, {'available': value});

  static Future<void> jobAction(JobRequest job, String action,
          [Map<String, dynamic> extra = const {}]) =>
      _api.post(ApiEndpoints.jobs,
          {'action': action, 'job_id': int.parse(job.id), ...extra});

  static Future<void> uploadJobPhoto(JobRequest job, String path) =>
      _api.postForm(ApiEndpoints.jobs, {'action': 'photo', 'job_id': job.id},
          files: [ApiFile('photo', path)]);
}
