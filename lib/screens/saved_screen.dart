import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/review_widgets.dart';
import 'results_screen.dart';
import 'shop_screen.dart';

/// Client: my reservations (with cancel and review) and saved shops and parts.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return AppColors.green;
      case 'Completed':
        return AppColors.teal;
      case 'Cancelled':
        return AppColors.muted;
      default:
        return AppColors.orange;
    }
  }

  Future<void> _cancel(BuildContext context, Reservation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this reservation?'),
        content: Text('${r.item.part.name}\n${r.item.shop.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );
    if (ok == true) Repo.instance.cancelReservation(r);
  }

  Future<void> _review(BuildContext context, Reservation r) async {
    final sent = await showReviewSheet(
      context,
      title: 'Rate ${r.item.shop.name}',
      onSubmit: (stars, comment) {
        Repo.instance.addReview(
          targetId: r.item.shop.id,
          stars: stars,
          comment: comment,
        );
        Repo.instance.markReviewed(r);
      },
    );
    if (sent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review')),
      );
    }
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      );

  Widget _reservationCard(BuildContext context, Reservation r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.item.part.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                r.status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(r.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${r.item.shop.name} · ${formatDzd(r.item.stock.price)} DZD · pay at pickup',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (r.status == 'Pending')
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Waiting for the shop to confirm.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          if (r.isActive || (r.status == 'Completed' && !r.reviewed))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  if (r.isActive)
                    OutlinedButton(
                      onPressed: () => _cancel(context, r),
                      child: const Text('Cancel'),
                    ),
                  if (r.status == 'Completed' && !r.reviewed)
                    FilledButton.icon(
                      onPressed: () => _review(context, r),
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Rate this shop'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final shops = repo.shops
            .where((s) => repo.isFavoriteShop(s.id))
            .toList();
        final parts = repo.parts
            .where((p) => repo.isFavoritePart(p.id))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const Text(
              'Saved',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _title('My reservations'),
            if (repo.reservations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No reservation yet. Search a part and tap Reserve.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final r in repo.reservations) _reservationCard(context, r),
            _title('Favorite shops'),
            if (shops.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tap the heart on a shop page to save it here.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final s in shops)
              Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${s.distanceKm.toStringAsFixed(1)} km · ${s.hours}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ShopScreen(shop: s),
                    ),
                  ),
                ),
              ),
            _title('Favorite parts'),
            if (parts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tap the heart on a part result to save it here.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final p in parts)
              Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Serial ${p.oem}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResultsScreen(part: p),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
