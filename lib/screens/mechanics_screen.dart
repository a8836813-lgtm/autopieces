import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/futuristic.dart';

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
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const FadeSlideIn(
          child: GradientText(
            'Mechanics',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Near Jijel · within 15 km · sorted by rating',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < repo.mechanics.length; i++)
          FadeSlideIn(
            index: i + 1,
            child: _MechanicCard(mechanic: repo.mechanics[i]),
          ),
        const SizedBox(height: 22),
        const SectionHeader('Repair reports'),
        const SizedBox(height: 4),
        const Text(
          'Search real problems that mechanics already fixed.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Describe a problem, e.g. grinding noise',
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: const Icon(Icons.search, color: AppColors.teal),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: border,
            enabledBorder: border,
          ),
        ),
        const SizedBox(height: 12),
        if (reports.isEmpty)
          const EmptyState(
            icon: Icons.find_in_page_outlined,
            title: 'No report yet',
            message: 'No report matches this problem yet.',
          ),
        for (final r in reports) _ReportCard(report: r),
      ],
    );
  }
}

class _MechanicCard extends StatelessWidget {
  final Mechanic mechanic;

  const _MechanicCard({required this.mechanic});

  @override
  Widget build(BuildContext context) {
    final initial =
        mechanic.name.isEmpty ? '?' : mechanic.name.substring(0, 1);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      glow: mechanic.premium,
      accent: mechanic.premium ? AppColors.orange : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.neon,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surface,
              child: Text(
                initial.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (mechanic.premium)
                      const StatusChip(
                        label: 'Premium',
                        color: AppColors.orange,
                        icon: Icons.workspace_premium,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.orange),
                    const SizedBox(width: 3),
                    Text(
                      '${mechanic.rating}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '  (${mechanic.reviews})   ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const Icon(Icons.near_me_outlined,
                        size: 14, color: AppColors.teal),
                    const SizedBox(width: 3),
                    Text(
                      '${mechanic.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${mechanic.specialties} · ${mechanic.reportsCount} published reports',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
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

  Widget _section(String label, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 44,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.directions_car_outlined,
                  size: 14, color: AppColors.muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${report.car} · ${report.mechanicName}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
          _section('PROBLEM', report.problem, AppColors.warn),
          _section('DIAGNOSIS', report.diagnosis, AppColors.orange),
          _section('WORK DONE', report.workDone, AppColors.green),
          const SizedBox(height: 14),
          StatusChip(
            label: '${formatDzd(report.cost)} DZD · labor + parts',
            color: AppColors.teal,
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }
}
