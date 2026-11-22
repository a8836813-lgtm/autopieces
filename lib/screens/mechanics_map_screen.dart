import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/maps_service.dart';
import '../services/places_service.dart';
import '../theme.dart';
import '../widgets/pill.dart';
import 'mechanic_detail_screen.dart';

/// Built-in map of mechanics near the user. Each mechanic has a card with its
/// opening and closing times, read live from Google Maps (Places API) when a
/// key is configured, otherwise from the demo data.
class MechanicsMapScreen extends StatefulWidget {
  const MechanicsMapScreen({super.key});

  @override
  State<MechanicsMapScreen> createState() => _MechanicsMapScreenState();
}

class _MechanicsMapScreenState extends State<MechanicsMapScreen> {
  // Used only when the phone gives no location (Algiers city centre).
  static const LatLng _fallbackCenter = LatLng(36.7538, 3.0588);

  final MapController _map = MapController();
  final PageController _pages = PageController(viewportFraction: 0.9);
  Timer? _refresh;

  LatLng _center = _fallbackCenter;
  LatLng? _me;
  bool _loading = true;
  bool _locationOff = false;
  bool _permissionDenied = false;
  PlacesResult? _result;
  int _selected = 0;

  List<NearbyMechanic> get _items => _result?.mechanics ?? const [];

  @override
  void initState() {
    super.initState();
    _start();
    // Re-read Google every 5 minutes so opening hours stay current.
    _refresh = Timer.periodic(const Duration(minutes: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _pages.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _locate();
    await _load();
  }

  Future<void> _locate() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _locationOff = true);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _locationOff = false;
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _me = LatLng(pos.latitude, pos.longitude);
        _center = _me!;
        _locationOff = false;
        _permissionDenied = false;
      });
    } catch (_) {
      // Keep the fallback centre; the banner explains what to do.
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final res = await PlacesService.nearbyMechanics(_center);
    if (!mounted) return;
    setState(() {
      _result = res;
      _loading = false;
      if (_selected >= res.mechanics.length) _selected = 0;
    });
    _map.move(_center, 14);
  }

  Future<void> _turnLocationOn() async {
    if (_permissionDenied) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> _recenter() async {
    await _locate();
    await _load();
  }

  void _select(int i, {bool fromPage = false}) {
    setState(() => _selected = i);
    _map.move(_items[i].position, 15);
    if (!fromPage && _pages.hasClients) {
      _pages.animateToPage(i,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanics near you'),
        actions: [
          IconButton(
            tooltip: 'Refresh hours',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(initialCenter: _center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.autopieces',
              ),
              MarkerLayer(
                markers: [
                  if (_me != null)
                    Marker(
                      point: _me!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  for (var i = 0; i < items.length; i++)
                    Marker(
                      point: items[i].position,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _select(i),
                        child: _pin(items[i], i == _selected),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                if (_locationOff || _permissionDenied) _locationBanner(),
                if (_result?.note != null) _noteBanner(_result!.note!),
              ],
            ),
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          Positioned(
            right: 12,
            bottom: 250,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.teal,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            height: 228,
            child: items.isEmpty
                ? const SizedBox.shrink()
                : PageView.builder(
                    controller: _pages,
                    itemCount: items.length,
                    onPageChanged: (i) => _select(i, fromPage: true),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _MechanicMapCard(item: items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pin(NearbyMechanic m, bool selected) {
    final open = m.openNow;
    final color = open == null
        ? AppColors.muted
        : (open ? AppColors.green : AppColors.danger);
    return Icon(
      Icons.location_on,
      size: selected ? 44 : 34,
      color: selected ? AppColors.orange : color,
    );
  }

  Widget _locationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _permissionDenied
                  ? 'Location permission is off.'
                  : 'Location is turned off.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _turnLocationOn,
            child: Text(_permissionDenied ? 'Settings' : 'Turn on'),
          ),
        ],
      ),
    );
  }

  Widget _noteBanner(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.warn)),
          ),
        ],
      ),
    );
  }
}

class _MechanicMapCard extends StatelessWidget {
  final NearbyMechanic item;

  const _MechanicMapCard({required this.item});

  Future<void> _call(BuildContext context) async {
    if (item.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: item.phone.replaceAll(' ', ''));
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start the call.')),
      );
    }
  }

  void _showHours(BuildContext context) {
    final now = DateTime.now();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                item.live ? 'Live from Google Maps' : 'Demo hours',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (item.weekdayHours.isEmpty)
                Text(item.hoursLabel ?? 'Hours not available')
              else
                for (var i = 0; i < item.weekdayHours.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      item.weekdayHours[i],
                      style: TextStyle(
                        fontWeight: i == now.weekday - 1
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: i == now.weekday - 1
                            ? AppColors.teal
                            : AppColors.ink,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final open = item.openNow;
    final change = item.nextChangeText(now);
    final today = item.todayHours(now) ?? item.hoursLabel;
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (open != null)
                  Pill(
                    text: open ? 'Open now' : 'Closed',
                    color: open ? AppColors.green : AppColors.danger,
                    background: open ? AppColors.greenBg : AppColors.dangerBg,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                '${item.distanceKm.toStringAsFixed(1)} km',
                if (item.rating != null)
                  'Rating ${item.rating!.toStringAsFixed(1)} (${item.reviews})',
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            if (change != null)
              Text(
                change,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: open == true ? AppColors.green : AppColors.warn,
                ),
              ),
            if (today != null)
              Text(
                'Today: $today',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            if (change == null && today == null)
              const Text('Hours not listed',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(
              item.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const Spacer(),
            Row(
              children: [
                if (item.phone.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(context),
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call'),
                    ),
                  ),
                if (item.phone.isNotEmpty) const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showHours(context),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Hours'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: item.profile != null
                        ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) =>
                                  MechanicDetailScreen(mechanic: item.profile!),
                            ))
                        : () => MapsService.openPlace(context,
                            name: item.name, address: item.address),
                    icon: Icon(
                        item.profile != null ? Icons.person : Icons.directions,
                        size: 16),
                    label: Text(item.profile != null ? 'Profile' : 'Route'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
