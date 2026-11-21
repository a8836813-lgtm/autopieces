import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/review_widgets.dart';

/// A shop's public page: details, reviews and the parts it has in stock.
class ShopScreen extends StatefulWidget {
  final Shop shop;

  const ShopScreen({super.key, required this.shop});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    // Counts as one view in the shop owner's Insights tab.
    Repo.instance.logView(widget.shop.id);
  }

  Future<void> _writeReview(Reservation r) async {
    final sent = await showReviewSheet(
      context,
      title: 'Rate ${widget.shop.name}',
      onSubmit: (stars, comment) {
        Repo.instance.addReview(
          targetId: widget.shop.id,
          stars: stars,
          comment: comment,
        );
        Repo.instance.markReviewed(r);
      },
    );
    if (sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final shop = widget.shop;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final items = repo.stockOfShop(shop.id);
        final reviews = repo.reviewsFor(shop.id);
        final avg = repo.averageStars(shop.id) ?? shop.rating;
        final favorite = repo.isFavoriteShop(shop.id);
        final reviewable = repo.reviewableReservationAt(shop.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              shop.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: favorite ? 'Remove from favorites' : 'Save shop',
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? AppColors.orange : null,
                ),
                onPressed: () => repo.toggleFavoriteShop(shop.id),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    Row(
                      children: [
                        StarRow(stars: avg),
                        const SizedBox(width: 6),
                        Text(
                          '${avg.toStringAsFixed(1)} · ${shop.distanceKm.toStringAsFixed(1)} km · ${shop.partsCount} parts',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reviews (${reviews.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (reviewable != null)
                    TextButton.icon(
                      onPressed: () => _writeReview(reviewable),
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Write a review'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (reviews.isEmpty)
                const Text(
                  'No review yet. You can review a shop after you picked up a reserved part.',
                  style: TextStyle(color: AppColors.muted),
                ),
              for (final r in reviews) ReviewTile(review: r),
            ],
          ),
        );
      },
    );
  }
}
