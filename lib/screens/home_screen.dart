import 'package:material_ui/material_ui.dart';

import '../data/repo.dart';
import '../data/vehicles.dart';
import '../models/search_query.dart';
import '../services/auth_service.dart';
import '../services/maps_service.dart';
import '../theme.dart';
import '../widgets/shop_slide_card.dart';
import '../widgets/vehicle_quick_search.dart';
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

  /// The client's saved car (demo): VW Golf 7. Used by the "Your car" button.
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

  /// Full vehicle search (all brands, models, serial number). When the user
  /// taps "Search parts" it returns a [SearchQuery] that opens the results.
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AutoPièces',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.teal,
              ),
            ),
            CircleAvatar(
              backgroundColor: AppColors.teal,
              child: Text(initial,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'What does your car need?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: 'Part name or number',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: border,
                  enabledBorder: border,
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search),
                    onPressed: () => _search(_controller.text),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: Tooltip(
                message: 'Scan a part with the camera',
                child: FilledButton(
                  onPressed: _openScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.photo_camera_outlined),
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
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _showResults(_myCar),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            alignment: Alignment.centerLeft,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Your car: VW Golf 7 · 2016'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Shops near you',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () => MapsService.openMechanicsNearMe(context),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Map'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
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
        const SizedBox(height: 24),
        const Text(
          'Browse by category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            for (final c in _categories)
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _search(c.query),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(c.icon, color: AppColors.teal, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        c.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
