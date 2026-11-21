import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';

/// A shop's public page: details and the parts it has in stock.
class ShopScreen extends StatelessWidget {
  final Shop shop;

  const ShopScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          shop.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final items = repo.stockOfShop(shop.id);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.type,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${shop.distanceKm.toStringAsFixed(1)} km · Rating ${shop.rating} · ${shop.partsCount} parts',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.hours,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: shop.openNow ? AppColors.green : AppColors.warn,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone (demo number): ${shop.phone}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Parts in stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'This shop has not listed any parts yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final s in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                              repo.partById(s.partId).name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stockLabel(s.quantity),
                              style: TextStyle(
                                fontSize: 13,
                                color: s.quantity <= 1
                                    ? AppColors.warn
                                    : AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatDzd(s.price)} DZD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
