import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../data/scan_mode.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/futuristic.dart';
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
        for (var i = 0; i < items.length; i++)
          Builder(
            builder: (context) {
              final s = items[i];
              final part = repo.partById(s.partId);
              return FadeSlideIn(
                index: i,
                child: GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.zero,
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
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No reservations yet',
          message:
              'Reserve a part from the client side at this shop to see it here.',
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
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      accent: pending ? AppColors.orange : AppColors.green,
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
    return AppScaffold(
      appBar: AppBar(
        title: Text('${shop.name} · Shop mode'),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) =>
            _tab == 0 ? _stockTab(repo) : _reservationsTab(repo),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scan,
        icon: const Icon(Icons.center_focus_strong_outlined),
        label: const Text('Scan a part'),
      ),
      bottomNavigationBar: GlassNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        items: const [
          NavItem(Icons.inventory_2_outlined, 'Stock',
              activeIcon: Icons.inventory_2),
          NavItem(Icons.receipt_long_outlined, 'Reservations',
              activeIcon: Icons.receipt_long),
        ],
      ),
    );
  }
}
