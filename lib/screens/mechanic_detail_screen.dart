import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../services/maps_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/mechanic_card.dart';
import '../widgets/pill.dart';
import '../widgets/rating_stars.dart';
import '../widgets/report_card.dart';
import '../widgets/review_widgets.dart';

/// Full profile of one mechanic: trust stats, services with prices, info
/// and the repair reports this mechanic published.
class MechanicDetailScreen extends StatelessWidget {
  final Mechanic mechanic;

  const MechanicDetailScreen({super.key, required this.mechanic});

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _rate(BuildContext context) async {
    final sent = await showReviewSheet(
      context,
      title: 'Rate ${mechanic.name}',
      onSubmit: (stars, comment, photos) => Repo.instance.addReview(
        targetId: mechanic.id,
        stars: stars,
        comment: comment,
        photos: photos,
      ),
    );
    if (sent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = mechanic;
    return Scaffold(
      appBar: AppBar(title: Text(m.name)),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => callMechanic(context, m),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => showAppointmentSheet(context, m),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Request appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Repo.instance,
        builder: (context, _) {
          final repo = Repo.instance;
          final reports = repo.reportsForMechanic(m.id);
          final written = repo.reviewsFor(m.id);
          final avg = repo.averageStars(m.id) ?? m.rating;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  MechanicAvatar(mechanic: m, radius: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingStars(rating: avg),
                            const SizedBox(width: 6),
                            Text(
                              avg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (m.verified)
                              const Pill(
                                text: 'Verified',
                                icon: Icons.verified,
                                color: AppColors.teal,
                                background: Color(0xFFDCEBEE),
                              ),
                            if (Repo.instance.isMechanicFeatured(m))
                              const Pill(
                                text: 'Featured',
                                color: AppColors.warn,
                                background: AppColors.warnBg,
                              ),
                            Pill(
                              text: Repo.instance.isMechanicOpen(m)
                                  ? 'Open now'
                                  : 'Closed',
                              color: Repo.instance.isMechanicOpen(m)
                                  ? AppColors.green
                                  : AppColors.danger,
                              background: Repo.instance.isMechanicOpen(m)
                                  ? AppColors.greenBg
                                  : AppColors.dangerBg,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _stat('${m.reviews + written.length}', 'Reviews'),
                  const SizedBox(width: 8),
                  _stat('${m.yearsExperience} yrs', 'Experience'),
                  const SizedBox(width: 8),
                  _stat('${reports.length}', 'Reports'),
                  const SizedBox(width: 8),
                  _stat('${m.distanceKm.toStringAsFixed(1)} km', 'Away'),
                ],
              ),
              _heading('About'),
              Text(m.about, style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final s in m.specialties) Pill(text: s)],
              ),
              _heading('Services and prices'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < m.services.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        title: Text(
                          m.services[i].name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          'From ${formatDzd(m.services[i].priceFrom)} DZD',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => showAppointmentSheet(
                            context,
                            m,
                            presetService: m.services[i].name,
                          ),
                          child: const Text('Book'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Starting prices. The final quote depends on the car and the parts.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              _heading('Details'),
              _infoRow(Icons.place_outlined, m.address),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => MapsService.openPlace(
                    context,
                    name: m.name,
                    address: m.address,
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open in Google Maps'),
                ),
              ),
              _infoRow(Icons.schedule, m.hours),
              _infoRow(Icons.phone_outlined, m.phone),
              _infoRow(Icons.chat_bubble_outline, m.responseTime),
              _infoRow(Icons.translate, m.languages.join(', ')),
              if (m.mobileService)
                _infoRow(Icons.directions_car_outlined, 'Comes to you'),
              _heading('Reviews (${written.length})'),
              for (final rv in written) ReviewTile(review: rv),
              OutlinedButton.icon(
                onPressed: () => _rate(context),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Rate this mechanic'),
              ),
              _heading('Repair reports (${reports.length})'),
              if (reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No published reports yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final r in reports)
                ReportCard(
                  report: r,
                  helpfulCount: repo.helpfulCountFor(r),
                  isHelpful: repo.isHelpful(r.key),
                  onHelpful: () => repo.toggleHelpful(r.key),
                ),
            ],
          );
        },
      ),
    );
  }
}
