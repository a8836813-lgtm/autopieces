import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import 'shop_screen.dart';

/// Radar-style map of the shops around the client.
///
/// The prototype has no GPS yet, so each shop is drawn at its distance and
/// direction from the client. When real latitude and longitude exist, replace
/// this screen with a real map package (for example flutter_map).
class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  Shop? _selected;

  @override
  Widget build(BuildContext context) {
    final shops = Repo.instance.shops;
    final maxKm = shops.fold<double>(0, (m, s) => math.max(m, s.distanceKm));
    final double range = (maxKm.ceilToDouble() + 1).clamp(2.0, 100.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shops near you',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = math.min(box.maxWidth, box.maxHeight);
                  final radius = size / 2 - 28;
                  final center = Offset(box.maxWidth / 2, box.maxHeight / 2);

                  Offset place(Shop s) {
                    final a = s.bearing * math.pi / 180;
                    final r = s.distanceKm / range * radius;
                    return Offset(
                      center.dx + r * math.sin(a),
                      center.dy - r * math.cos(a),
                    );
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RingsPainter(
                            center: center,
                            radius: radius,
                            rings: range.floor().clamp(1, 6).toInt(),
                            range: range,
                          ),
                        ),
                      ),
                      Positioned(
                        left: center.dx - 14,
                        top: center.dy - 14,
                        child: const Icon(Icons.my_location,
                            size: 28, color: AppColors.teal),
                      ),
                      for (var i = 0; i < shops.length; i++)
                        Positioned(
                          left: place(shops[i]).dx - 18,
                          top: place(shops[i]).dy - 18,
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = shops[i]),
                            child: Tooltip(
                              message: shops[i].name,
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: shops[i] == _selected
                                      ? AppColors.orange
                                      : (shops[i].openNow
                                          ? AppColors.teal
                                          : AppColors.muted),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Prototype view: shops are drawn by distance and direction. A real map comes with GPS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            SizedBox(
              height: 168,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                itemCount: shops.length,
                itemBuilder: (context, i) {
                  final s = shops[i];
                  final selected = s == _selected;
                  return Card(
                    color: selected ? AppColors.greenBg : AppColors.surface,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected ? AppColors.teal : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            s.openNow ? AppColors.teal : AppColors.muted,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(s.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${s.distanceKm.toStringAsFixed(1)} km · ${s.hours}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ShopScreen(shop: s),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final int rings;
  final double range;

  _RingsPainter({
    required this.center,
    required this.radius,
    required this.rings,
    required this.range,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFF0E1526);
    canvas.drawCircle(center, radius, fill);

    final line = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 1; i <= rings; i++) {
      final r = radius * (i / range);
      if (r <= radius) canvas.drawCircle(center, r, line);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i km',
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (r <= radius) tp.paint(canvas, Offset(center.dx + 4, center.dy - r));
    }
    canvas.drawCircle(center, radius, line);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.center != center || old.radius != radius || old.range != range;
}
