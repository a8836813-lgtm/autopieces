import 'package:material_ui/material_ui.dart';

import '../data/repo.dart';
import '../theme.dart';
import '../widgets/futuristic.dart';
import '../widgets/shop_slide_card.dart';
import 'results_screen.dart';
import 'scan_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _Category {
  final String label;
  final String query;
  final IconData icon;
  const _Category(this.label, this.query, this.icon);
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  static const List<_Category> _categories = [
    _Category('Tires', 'tire', Icons.tire_repair),
    _Category('Rims', 'rim', Icons.album_outlined),
    _Category('Brakes', 'brake', Icons.adjust),
    _Category('Engine', 'engine', Icons.settings_outlined),
    _Category('Battery', 'battery', Icons.battery_charging_full),
    _Category('Filters', 'filter', Icons.filter_alt_outlined),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String text) {
    final query = text.trim();
    if (query.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ResultsScreen(query: query)),
    );
  }

  void _openScan() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = Repo.instance.shops;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(
                    'AUTOPIÈCES',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'LOCAL PARTS GRID',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 2,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.neon,
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surface,
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'What does your',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w300,
            height: 1.1,
            color: AppColors.ink,
          ),
        ),
        const GradientText(
          'car need?',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.18),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: 'Part name or number',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.teal),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.teal,
                      onPressed: () => _search(_controller.text),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: 'Scan a part with the camera',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.neon,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _openScan,
                    child: const Icon(
                      Icons.center_focus_strong_outlined,
                      color: AppColors.onNeon,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () {},
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: const Row(
            children: [
              NeonIconBadge(
                icon: Icons.directions_car_outlined,
                size: 38,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VW Golf 7 · 2016',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Your vehicle',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusChip(label: 'Active', color: AppColors.green),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('${shops.length}', 'Shops online', AppColors.teal),
            const SizedBox(width: 10),
            _stat('AI', 'Part scanner', AppColors.orange),
            const SizedBox(width: 10),
            _stat('24/7', 'Live stock', AppColors.green),
          ],
        ),
        const SizedBox(height: 26),
        const SectionHeader('Shops near you'),
        const SizedBox(height: 12),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final shop = shops[i];
              return ShopSlideCard(
                shop: shop,
                highlighted: i == 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShopScreen(shop: shop),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),
        const SectionHeader('Browse by category'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            for (var i = 0; i < _categories.length; i++)
              GlassCard(
                padding: EdgeInsets.zero,
                onTap: () => _search(_categories[i].query),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NeonIconBadge(
                      icon: _categories[i].icon,
                      size: 42,
                      color: i.isEven ? AppColors.teal : AppColors.orange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _categories[i].label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        radius: 14,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
