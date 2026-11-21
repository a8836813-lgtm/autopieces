import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../theme.dart';
import 'futuristic.dart';

class ShopSlideCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;
  final bool highlighted;

  const ShopSlideCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: GlassCard(
        onTap: onTap,
        glow: highlighted,
        accent: highlighted ? AppColors.teal : null,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (highlighted)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: StatusChip(label: 'Closest'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              shop.type,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.near_me_outlined,
                    size: 14, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(
                  '${shop.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded,
                    size: 15, color: AppColors.orange),
                const SizedBox(width: 3),
                Text(
                  '${shop.rating}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              shop.hours,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: shop.openNow ? AppColors.green : AppColors.warn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
