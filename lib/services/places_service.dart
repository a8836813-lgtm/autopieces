import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../data/models.dart';
import '../data/repo.dart';

/// One opening period from Google (day: 0 = Sunday ... 6 = Saturday).
class HoursPeriod {
  final int openDay, openHour, openMinute;
  final int closeDay, closeHour, closeMinute;

  const HoursPeriod({
    required this.openDay,
    required this.openHour,
    required this.openMinute,
    required this.closeDay,
    required this.closeHour,
    required this.closeMinute,
  });
}

/// A mechanic shown on the map. Comes from Google Places (live) or from the
/// demo data when no API key is set.
class NearbyMechanic {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final double? rating;
  final int reviews;
  final String phone;
  final double distanceKm;

  /// null = Google did not say.
  final bool? openNow;

  /// Seven lines, Monday first, e.g. "Monday: 8:00 AM – 6:00 PM".
  final List<String> weekdayHours;
  final List<HoursPeriod> periods;

  /// Set only for demo mechanics so the card can open the full profile.
  final Mechanic? profile;

  /// One-line hours for demo mechanics (e.g. "Mon-Sat 8:00-18:00").
  final String? hoursLabel;
  final bool live;

  const NearbyMechanic({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.distanceKm,
    this.rating,
    this.reviews = 0,
    this.phone = '',
    this.openNow,
    this.weekdayHours = const [],
    this.periods = const [],
    this.profile,
    this.hoursLabel,
    this.live = false,
  });

  /// "Tuesday: 8:00 AM – 6:00 PM" → "8:00 AM – 6:00 PM" for today.
  String? todayHours(DateTime now) {
    final i = now.weekday - 1; // DateTime: Monday = 1
    if (i < 0 || i >= weekdayHours.length) return null;
    final line = weekdayHours[i];
    final cut = line.indexOf(':');
    return cut == -1 ? line : line.substring(cut + 1).trim();
  }

  static String _fmt(int h, int m) {
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// "Closes at 18:00" / "Opens at 08:00" / "Opens Mon at 08:00".
  /// Null when Google gave no periods.
  String? nextChangeText(DateTime now) {
    if (periods.isEmpty || openNow == null) return null;
    final gDay = now.weekday % 7; // Google: Sunday = 0
    final minutes = now.hour * 60 + now.minute;
    if (openNow == true) {
      for (final p in periods) {
        final start = p.openDay * 1440 + p.openHour * 60 + p.openMinute;
        var end = p.closeDay * 1440 + p.closeHour * 60 + p.closeMinute;
        final cur = gDay * 1440 + minutes;
        if (end < start) end += 7 * 1440;
        if ((cur >= start && cur < end) || (cur + 7 * 1440 >= start && cur + 7 * 1440 < end)) {
          return 'Closes at ${_fmt(p.closeHour, p.closeMinute)}';
        }
      }
      return null;
    }
    // Closed: find the next opening.
    final cur = gDay * 1440 + minutes;
    HoursPeriod? best;
    var bestDelta = 1 << 30;
    for (final p in periods) {
      final start = p.openDay * 1440 + p.openHour * 60 + p.openMinute;
      var delta = start - cur;
      if (delta < 0) delta += 7 * 1440;
      if (delta < bestDelta) {
        bestDelta = delta;
        best = p;
      }
    }
    if (best == null) return null;
    final t = _fmt(best.openHour, best.openMinute);
    if (bestDelta < 1440 && best.openDay == gDay) return 'Opens at $t';
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return 'Opens ${days[best.openDay % 7]} at $t';
  }
}

class PlacesResult {
  final List<NearbyMechanic> mechanics;

  /// True when the data really came from Google Maps.
  final bool live;

  /// Human readable problem (bad key, no network...) or null.
  final String? note;

  const PlacesResult(this.mechanics, {required this.live, this.note});
}

/// Finds mechanics around a point and their opening hours.
///
/// With a Google Places API key (AppConfig.googlePlacesApiKey) the data is read
/// live from Google Maps every time, so a change of hours made on Google shows
/// up in the app. Without a key the demo mechanics are used.
class PlacesService {
  PlacesService._();

  static const _endpoint = 'https://places.googleapis.com/v1/places:searchNearby';

  static const _fieldMask = 'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.rating,places.userRatingCount,'
      'places.nationalPhoneNumber,places.currentOpeningHours,'
      'places.regularOpeningHours';

  static Future<PlacesResult> nearbyMechanics(LatLng center,
      {double radiusMeters = 5000}) async {
    if (!AppConfig.googlePlacesConfigured) {
      return PlacesResult(
        _demo(center),
        live: false,
        note: 'Demo data. Add GOOGLE_PLACES_API_KEY to get live hours.',
      );
    }
    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': AppConfig.googlePlacesApiKey,
              'X-Goog-FieldMask': _fieldMask,
            },
            body: jsonEncode({
              'includedTypes': ['car_repair'],
              'maxResultCount': 20,
              'rankPreference': 'DISTANCE',
              'locationRestriction': {
                'circle': {
                  'center': {
                    'latitude': center.latitude,
                    'longitude': center.longitude,
                  },
                  'radius': radiusMeters,
                },
              },
            }),
          )
          .timeout(AppConfig.requestTimeout);
      if (res.statusCode != 200) {
        return PlacesResult(_demo(center),
            live: false,
            note: 'Google Maps error ${res.statusCode}. Showing demo data.');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = (data['places'] as List?) ?? const [];
      final list = raw
          .whereType<Map<String, dynamic>>()
          .map((m) => _parse(m, center))
          .whereType<NearbyMechanic>()
          .toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (list.isEmpty) {
        return const PlacesResult([],
            live: true, note: 'No mechanics found within 5 km.');
      }
      return PlacesResult(list, live: true);
    } catch (_) {
      return PlacesResult(_demo(center),
          live: false, note: 'No connection to Google Maps. Showing demo data.');
    }
  }

  static NearbyMechanic? _parse(Map<String, dynamic> m, LatLng center) {
    final loc = m['location'] as Map<String, dynamic>?;
    if (loc == null) return null;
    final pos = LatLng(
      (loc['latitude'] as num).toDouble(),
      (loc['longitude'] as num).toDouble(),
    );
    // currentOpeningHours is what Google shows today (holidays included).
    final hours = (m['currentOpeningHours'] ?? m['regularOpeningHours'])
        as Map<String, dynamic>?;
    final periods = <HoursPeriod>[];
    for (final p in (hours?['periods'] as List?) ?? const []) {
      if (p is! Map<String, dynamic>) continue;
      final o = p['open'] as Map<String, dynamic>?;
      final c = p['close'] as Map<String, dynamic>?;
      if (o == null || c == null) continue; // open 24h has no close
      periods.add(HoursPeriod(
        openDay: (o['day'] as num?)?.toInt() ?? 0,
        openHour: (o['hour'] as num?)?.toInt() ?? 0,
        openMinute: (o['minute'] as num?)?.toInt() ?? 0,
        closeDay: (c['day'] as num?)?.toInt() ?? 0,
        closeHour: (c['hour'] as num?)?.toInt() ?? 0,
        closeMinute: (c['minute'] as num?)?.toInt() ?? 0,
      ));
    }
    final name = (m['displayName'] as Map<String, dynamic>?)?['text'] as String?;
    return NearbyMechanic(
      id: (m['id'] as String?) ?? name ?? '',
      name: name ?? 'Mechanic',
      address: (m['formattedAddress'] as String?) ?? '',
      position: pos,
      distanceKm: _km(center, pos),
      rating: (m['rating'] as num?)?.toDouble(),
      reviews: (m['userRatingCount'] as num?)?.toInt() ?? 0,
      phone: (m['nationalPhoneNumber'] as String?) ?? '',
      openNow: hours?['openNow'] as bool?,
      weekdayHours:
          ((hours?['weekdayDescriptions'] as List?) ?? const []).cast<String>(),
      periods: periods,
      live: true,
    );
  }

  static double _km(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(
          a.latitude, a.longitude, b.latitude, b.longitude) /
      1000;

  /// Demo mechanics placed around [center] at their stored distance.
  static List<NearbyMechanic> _demo(LatLng center) {
    final list = Repo.instance.mechanics;
    final out = <NearbyMechanic>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final angle = (i * 2.399963); // golden angle, spreads pins evenly
      final dLat = (m.distanceKm / 111.0) * math.cos(angle);
      final dLng = (m.distanceKm / 111.0) * math.sin(angle);
      out.add(NearbyMechanic(
        id: m.id,
        name: m.name,
        address: m.address,
        position: LatLng(center.latitude + dLat, center.longitude + dLng),
        distanceKm: m.distanceKm,
        rating: m.rating,
        reviews: m.reviews,
        phone: m.phone,
        openNow: Repo.instance.isMechanicOpen(m),
        weekdayHours: const [],
        profile: m,
        hoursLabel: m.hours,
      ));
    }
    return out;
  }
}
