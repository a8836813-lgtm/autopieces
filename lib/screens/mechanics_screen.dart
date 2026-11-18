import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/review_widgets.dart';

/// Mechanics directory plus a searchable list of repair reports.
class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});

  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    final reports = repo.searchReports(_query);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text(
          'Mechanics near Jijel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Within 15 km · sorted by rating',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (final m in repo.mechanics) _MechanicCard(mechanic: m),
        const SizedBox(height: 20),
        const Text(
          'Repair reports',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Search real problems that mechanics already fixed.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Describe a problem, e.g. grinding noise',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: border,
            enabledBorder: border,
          ),
        ),
        const SizedBox(height: 12),
        if (reports.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No report matches this problem yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final r in reports) _ReportCard(report: r),
      ],
    );
  }
}

class _MechanicCard extends StatelessWidget {
  final Mechanic mechanic;

  const _MechanicCard({required this.mechanic});

  Future<void> _rate(BuildContext context) async {
    final sent = await showReviewSheet(
      context,
      title: 'Rate ${mechanic.name}',
      onSubmit: (stars, comment) => Repo.instance.addReview(
        targetId: mechanic.id,
        stars: stars,
        comment: comment,
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
    final repo = Repo.instance;
    final written = repo.reviewsFor(mechanic.id);
    final avg = repo.averageStars(mechanic.id) ?? mechanic.rating;
    final reportsCount = repo.reportsOf(mechanic.name).length;
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
                  mechanic.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (mechanic.premium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE7D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              StarRow(stars: avg, size: 15),
              const SizedBox(width: 6),
              Text(
                '${avg.toStringAsFixed(1)} · ${mechanic.reviews + written.length} reviews · ${mechanic.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${mechanic.specialties} · $reportsCount published reports',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _rate(context),
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Rate this mechanic'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final RepairReport report;

  const _ReportCard({required this.report});

  Widget _section(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${report.car} · ${report.mechanicName}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          _section('PROBLEM', report.problem),
          _section('DIAGNOSIS', report.diagnosis),
          _section('WORK DONE', report.workDone),
          const SizedBox(height: 10),
          Text(
            'Labor and parts: ${formatDzd(report.cost)} DZD',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
