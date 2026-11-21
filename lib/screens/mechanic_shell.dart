import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/review_widgets.dart';
import 'auth/home_router.dart';
import 'report_edit_screen.dart';

/// Mechanic mode: own repair reports, publish a new one, profile and reviews.
class MechanicShell extends StatefulWidget {
  const MechanicShell({super.key});

  @override
  State<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends State<MechanicShell> {
  int _tab = 0;

  void _newReport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportEditScreen()),
    );
  }

  Widget _reportsTab(Repo repo) {
    final mine = repo.reportsOf(Repo.myMechanicName);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Text(
          '${mine.length} published report${mine.length == 1 ? '' : 's'}. Clients find them when they search a problem.',
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (mine.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'You have not published a report yet.\nTap "New report" to write your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final r in mine) _reportCard(r),
      ],
    );
  }

  Widget _reportCard(RepairReport r) {
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
          Text(
            r.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            r.car,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(r.diagnosis, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (r.parts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Parts: ${r.parts}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${formatDzd(r.cost)} DZD',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _profileTab(Repo repo) {
    final mechanic = repo.mechanics.firstWhere((m) => m.id == Repo.myMechanicId);
    final user = AuthService.instance.currentUser.value;
    final reviews = repo.reviewsFor(Repo.myMechanicId);
    final avg = repo.averageStars(Repo.myMechanicId) ?? mechanic.rating;
    final reportsCount = repo.reportsOf(Repo.myMechanicName).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
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
                user?.profile['garage'] ?? mechanic.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                user?.profile['specialty'] ?? mechanic.specialties.join(', '),
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StarRow(stars: avg, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${avg.toStringAsFixed(1)} · ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$reportsCount published reports',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Client reviews',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Text(
            'No review yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final r in reviews) ReviewTile(review: r),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => logoutToRoleSelect(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.warn,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mechanic space',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) =>
            _tab == 0 ? _reportsTab(repo) : _profileTab(repo),
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _newReport,
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note),
              label: const Text('New report'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'My reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
