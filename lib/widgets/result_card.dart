import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';

/// One search result: a part, the shop that has it, price, stock and distance.
class ResultCard extends StatelessWidget {
  final SearchResult result;
  final bool highlight;
  final VoidCallback onCall;
  final VoidCallback onReserve;

  const ResultCard({
    super.key,
    required this.result,
    required this.onCall,
    required this.onReserve,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final shop = result.shop;
    final quantity = result.stock.quantity;
    final lowStock = quantity <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.teal : AppColors.border,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Best match',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ),
          Text(
            result.part.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Serial ${result.part.oem} · ${result.part.fits}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${shop.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              Text(
                stockLabel(quantity),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: lowStock ? AppColors.warn : AppColors.green,
                ),
              ),
              Text(
                'Rating ${shop.rating}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              Text(
                Repo.instance.shopHoursOf(shop),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${formatDzd(result.stock.price)} DZD',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onCall,
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
                child: const Text('Call'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onReserve,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  minimumSize: const Size(64, 44),
                ),
                child: const Text('Reserve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
