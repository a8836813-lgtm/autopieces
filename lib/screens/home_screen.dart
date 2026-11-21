import 'package:material_ui/material_ui.dart';

import '../data/repo.dart';
import '../data/vehicles.dart';
import '../models/search_query.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/futuristic.dart';
import '../widgets/shop_slide_card.dart';
import '../widgets/vehicle_quick_search.dart';
import 'nearby_map_screen.dart';
import 'results_screen.dart';
import 'scan_screen.dart';
import 'shop_screen.dart';
import 'vehicle_search_screen.dart';

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

  /// The client's saved car (demo): VW Golf 7. Used by the "Your car" card.
  SearchQuery get _myCar => SearchQuery(
        type: VehicleType.car,
        brand: kCarBrands.firstWhere((b) => b.id == 'volkswagen'),
        model: 'Golf 7',
      );

  void _showResults(SearchQuery query) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(vehicleQuery: query),
      ),
    );
  }

  /// Full vehicle search (all brands, models, serial number).
  Future<void> _openVehicleSearch(VehicleBrand? brand) async {
    final query = await Navigator.of(context).push<SearchQuery>(
      MaterialPageRoute<SearchQuery>(
        builder: (_) => VehicleSearchScreen(initialBrand: brand),
      ),
    );
    if (query == null || !mounted) return;
    _showResults(query);
  }

  @override
  Widget build(BuildContext context) {
    final shops = Repo.instance.shops;
    final user = AuthService.instance.currentUser.value;
    final initial = (user != null && user.name.isNotEmpty)
        ? user.name[0].toUpperCase()
        : 'A';

    final children = <Widget>[
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
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surface,
                child: Text(
                  initial,
                  style: const TextStyle(
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
        const SizedBox(height: 14),
        VehicleQuickSearch(
          onSearch: _showResults,
          onOpenFull: (brand, type) => _openVehicleSearch(brand),
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () => _showResults(_myCar),
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
              LiveDot(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ScanHero(onTap: _openScan),
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
        Row(
          children: [
            const Expanded(child: SectionHeader('Shops near you')),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NearbyMapScreen(),
                ),
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Map'),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        for (var i = 0; i < children.length; i++)
          FadeSlideIn(index: i, child: children[i]),
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

/// Big call-to-action for the camera scanner.
class _ScanHero extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E3B52), Color(0xFF2B1B5E)],
          ),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusChip(
                    label: 'AI scanner',
                    color: AppColors.orange,
                    icon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Scan any part',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point your camera, we find the shops that have it in stock.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.ink.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.neon,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.center_focus_strong_outlined,
                size: 30,
                color: AppColors.onNeon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
