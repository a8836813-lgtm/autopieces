import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import 'pill.dart';
import 'rating_stars.dart';

/// Demo "call" action: shows the number, same as the shop results do.
void callMechanic(BuildContext context, Mechanic mechanic) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Calling ${mechanic.name} · ${mechanic.phone}')),
  );
}

/// Round monogram avatar for a mechanic.
class MechanicAvatar extends StatelessWidget {
  final Mechanic mechanic;
  final double radius;

  const MechanicAvatar({super.key, required this.mechanic, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.teal,
      child: Text(
        mechanic.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

/// One mechanic in the directory: trust signals, specialties and actions.
class MechanicCard extends StatelessWidget {
  final Mechanic mechanic;
  final int reportsCount;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onBook;

  const MechanicCard({
    super.key,
    required this.mechanic,
    required this.reportsCount,
    required this.onTap,
    required this.onCall,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final m = mechanic;
    final repo = Repo.instance;
    final avg = repo.averageStars(m.id) ?? m.rating;
    final reviewCount = m.reviews + repo.reviewsFor(m.id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MechanicAvatar(mechanic: m),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (m.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppColors.teal,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              RatingStars(rating: avg, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${avg.toStringAsFixed(1)} ($reviewCount)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${m.distanceKm.toStringAsFixed(1)} km · '
                            '${m.yearsExperience} years experience',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (Repo.instance.isMechanicFeatured(m))
                      const Pill(
                        text: 'Featured',
                        color: AppColors.warn,
                        background: AppColors.warnBg,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final s in m.specialties) Pill(text: s)],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: Repo.instance.isMechanicOpen(m)
                          ? AppColors.green
                          : AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m.hours,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '$reportsCount ${reportsCount == 1 ? 'report' : 'reports'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onBook,
                        icon: const Icon(
                          Icons.event_available_outlined,
                          size: 18,
                        ),
                        label: const Text('Book'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
