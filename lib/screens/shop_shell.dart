import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../data/scan_mode.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/review_widgets.dart';
import 'add_part_screen.dart';
import 'auth/home_router.dart';
import 'scan_screen.dart';
import 'stock_edit_screen.dart';

/// Shop-owner mode: stock list, reservations, and a scan button to check or
/// update stock without searching manually.
class ShopShell extends StatefulWidget {
  const ShopShell({super.key});

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int _tab = 0;

  void _scan() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScanScreen(mode: ScanMode.shop),
      ),
    );
  }

  Widget _stockTab(Repo repo) {
    final items = repo.stockOfShop(Repo.myShopId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Text(
          '${items.length} parts in your stock. Tap a part to edit it, or scan one from your shelf.',
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddPartScreen()),
          ),
          icon: const Icon(Icons.pin_outlined),
          label: const Text('Add a part by serial number'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        for (final s in items)
          Builder(
            builder: (context) {
              final part = repo.partById(s.partId);
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(
                    part.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${stockLabel(s.quantity)} · ${s.condition} · Serial ${part.oem}',
                  ),
                  trailing: Text(
                    '${formatDzd(s.price)} DZD',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StockEditScreen(part: part),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _reservationsTab(Repo repo) {
    final mine = repo.reservations
        .where((r) => r.item.shop.id == Repo.myShopId)
        .toList();
    if (mine.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No reservations yet.\nReserve a part from the client side at this shop to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        for (final r in mine) _reservationCard(repo, r),
      ],
    );
  }

  Widget _reservationCard(Repo repo, Reservation r) {
    final pending = r.status == 'Pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.item.part.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Client (demo) · ${formatDzd(r.item.stock.price)} DZD · ${r.status}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (pending)
            FilledButton(
              onPressed: () => repo.confirmReservation(r),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size(64, 44),
              ),
              child: const Text('Confirm'),
            )
          else if (r.status == 'Confirmed')
            FilledButton(
              onPressed: () => repo.completeReservation(r),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                minimumSize: const Size(64, 44),
              ),
              child: const Text('Picked up'),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.teal),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightsTab(Repo repo) {
    final items = repo.stockOfShop(Repo.myShopId);
    final views = repo.viewsByShop[Repo.myShopId] ?? 0;
    final calls = repo.callsByShop[Repo.myShopId] ?? 0;
    final reserved = repo.reservationsCountFor(Repo.myShopId);
    final low = items.where((s) => s.quantity <= 1).toList();
    final reviews = repo.reviewsFor(Repo.myShopId);
    final avg = repo.averageStars(Repo.myShopId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const Text(
          'How clients interact with your shop.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('Page views', '$views', Icons.visibility_outlined),
            const SizedBox(width: 10),
            _statCard('Calls', '$calls', Icons.call_outlined),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard('Reservations', '$reserved', Icons.receipt_long_outlined),
            const SizedBox(width: 10),
            _statCard(
              'Rating',
              avg == null ? '-' : avg.toStringAsFixed(1),
              Icons.star_outline,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Low stock',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (low.isEmpty)
          const Text(
            'Nothing running low.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final s in low)
          Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              title: Text(repo.partById(s.partId).name),
              subtitle: Text(stockLabel(s.quantity)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StockEditScreen(part: repo.partById(s.partId)),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Client reviews (${reviews.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Text(
            'No review yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final r in reviews) ReviewTile(review: r),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final shop = repo.shopById(Repo.myShopId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${shop.name} · Shop mode',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => logoutToRoleSelect(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) => switch (_tab) {
          0 => _stockTab(repo),
          1 => _reservationsTab(repo),
          _ => _insightsTab(repo),
        },
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _scan,
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Scan a part'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Reservations',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
