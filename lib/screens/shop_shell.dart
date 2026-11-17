import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../data/scan_mode.dart';
import '../theme.dart';
import '../utils.dart';
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
                    '${stockLabel(s.quantity)} · ${s.condition} · OEM ${part.oem}',
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
            ),
        ],
      ),
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
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) =>
            _tab == 0 ? _stockTab(repo) : _reservationsTab(repo),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scan,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Scan a part'),
      ),
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
        ],
      ),
    );
  }
}
