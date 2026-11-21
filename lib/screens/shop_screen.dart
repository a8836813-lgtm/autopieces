import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/futuristic.dart';

/// A shop's public page: details and the parts it has in stock.
class ShopScreen extends StatelessWidget {
  final Shop shop;

  const ShopScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return AppScaffold(
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
              FadeSlideIn(
                child: GlassCard(
                  glow: true,
                  accent: AppColors.teal,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NeonIconBadge(
                            icon: Icons.storefront_outlined,
                            size: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shop.type,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _info(Icons.near_me_outlined,
                              '${shop.distanceKm.toStringAsFixed(1)} km'),
                          _info(Icons.star_rounded, '${shop.rating}',
                              color: AppColors.orange),
                          _info(Icons.inventory_2_outlined,
                              '${shop.partsCount} parts'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          StatusChip(
                            label: shop.hours,
                            color:
                                shop.openNow ? AppColors.green : AppColors.warn,
                            icon: Icons.schedule,
                          ),
                          const Spacer(),
                          Text(
                            shop.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Parts in stock'),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Empty shelves',
                  message: 'This shop has not listed any parts yet.',
                ),
              for (var i = 0; i < items.length; i++)
                FadeSlideIn(
                  index: i + 1,
                  child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.partById(items[i].partId).name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stockLabel(items[i].quantity),
                              style: TextStyle(
                                fontSize: 13,
                                color: items[i].quantity <= 1
                                    ? AppColors.warn
                                    : AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatDzd(items[i].price)} DZD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String text, {Color color = AppColors.teal}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
