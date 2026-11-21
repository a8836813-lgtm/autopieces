import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';

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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: highlighted ? AppColors.teal : AppColors.border,
        width: highlighted ? 2 : 1,
      ),
    );
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.white,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shop.type,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const Spacer(),
                Text(
                  '${shop.distanceKm.toStringAsFixed(1)} km · Rating ${shop.rating}',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  Repo.instance.shopHoursOf(shop),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Repo.instance.isShopOpen(shop) ? AppColors.green : AppColors.warn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
