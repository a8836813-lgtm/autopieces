import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../services/auth_service.dart';
import '../services/photo_picker.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/mechanic_widgets.dart';
import '../widgets/photo_strip.dart';
import '../widgets/pill.dart';
import '../widgets/review_widgets.dart';
import 'auth/home_router.dart';
import 'estimate_screen.dart';
import 'invoice_screen.dart';
import 'mechanic_diagnostic_screen.dart';
import 'report_edit_screen.dart';
import 'results_screen.dart';
import 'scan_screen.dart';

/// Mechanic mode: dashboard, jobs, own repair reports, profile and reviews.
class MechanicShell extends StatefulWidget {
  const MechanicShell({super.key});

  @override
  State<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends State<MechanicShell> {
  int _tab = 0;
  String _jobFilter = 'New';
  final _reportSearch = TextEditingController();

  @override
  void dispose() {
    _reportSearch.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _newReport() => _go(const ReportEditScreen());

  void _editReport(RepairReport r) => _go(ReportEditScreen(existing: r));

  Future<void> _addJobPhoto(Repo repo, JobRequest j) async {
    final path = await PhotoPicker.pick(context);
    if (path == null) return;
    repo.addJobPhoto(j, path);
  }

  Future<void> _findPart() async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Find a part'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
          decoration: const InputDecoration(
            hintText: 'Part name or serial number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (query == null || query.trim().isEmpty || !mounted) return;
    _go(ResultsScreen(query: query.trim()));
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _garageName(Repo repo) {
    final user = AuthService.instance.currentUser.value;
    final mechanic = repo.mechanics.firstWhere((m) => m.id == Repo.myMechanicId);
    return user?.profile['garage'] ?? mechanic.name;
  }

  // -------------------------------------------------------------- dashboard

  Widget _dashboardTab(Repo repo) {
    final reviews = repo.reviewsFor(Repo.myMechanicId);
    final mechanic = repo.mechanics.firstWhere((m) => m.id == Repo.myMechanicId);
    final avg = repo.averageStars(Repo.myMechanicId) ?? mechanic.rating;
    final reportsCount = repo.reportsOf(Repo.myMechanicName).length;
    final week = repo.weeklyEarnings();
    final thisWeek = repo.weekEarnings;
    final lastWeek = repo.lastWeekEarnings;
    final newJobs = repo.jobsWithStatus({'New'}).length;
    final upNext = repo.jobsWithStatus({'Accepted', 'In progress'});

    String change;
    if (lastWeek == 0) {
      change = thisWeek == 0 ? 'No earnings yet' : 'First week with earnings';
    } else {
      final pct = ((thisWeek - lastWeek) * 100 / lastWeek).round();
      change = '${pct >= 0 ? '+' : ''}$pct% vs last week';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          '${_greeting()},',
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        Text(
          _garageName(repo),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 11,
                color: repo.mechanicAvailable
                    ? AppColors.green
                    : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo.mechanicAvailable
                          ? 'Available for new jobs'
                          : 'Busy, not taking new jobs',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Clients see this on your mechanic page',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: repo.mechanicAvailable,
                onChanged: repo.setMechanicAvailable,
              ),
            ],
          ),
        ),
        if (newJobs > 0)
          InfoCard(
            onTap: () => setState(() {
              _jobFilter = 'New';
              _tab = 1;
            }),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$newJobs new job request${newJobs == 1 ? '' : 's'} waiting for your answer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            StatTile(
              icon: Icons.description_outlined,
              value: '$reportsCount',
              label: 'Reports published',
            ),
            StatTile(
              icon: Icons.build_circle_outlined,
              value: '${repo.jobsDoneCount}',
              label: 'Jobs done',
              color: AppColors.green,
            ),
            StatTile(
              icon: Icons.star_rounded,
              value: '${avg.toStringAsFixed(1)} (${reviews.length})',
              label: 'Rating',
              color: AppColors.star,
            ),
            StatTile(
              icon: Icons.payments_outlined,
              value: '${formatDzd(thisWeek)} DZD',
              label: 'Earned this week',
              color: AppColors.orange,
            ),
          ],
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Earnings, last 7 days',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                change,
                style: TextStyle(
                  fontSize: 13,
                  color: thisWeek >= lastWeek ? AppColors.green : AppColors.danger,
                ),
              ),
              const SizedBox(height: 14),
              WeekBars(values: week),
            ],
          ),
        ),
        InfoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RateGauge(
                value: avg / 5,
                centerText: avg.toStringAsFixed(1),
                label: 'Rating',
                color: AppColors.star,
              ),
              RateGauge(
                value: repo.responseRate,
                label: 'Response',
              ),
              RateGauge(
                value: repo.completionRate,
                label: 'Completion',
                color: AppColors.green,
              ),
            ],
          ),
        ),
        const SectionLabel('Quick actions'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            QuickAction(
              icon: Icons.edit_note,
              label: 'New report',
              color: AppColors.orange,
              onTap: _newReport,
            ),
            QuickAction(
              icon: Icons.memory,
              label: 'Diagnose',
              onTap: () => _go(const MechanicDiagnosticScreen()),
            ),
            QuickAction(
              icon: Icons.calculate_outlined,
              label: 'Estimate',
              onTap: () => _go(const EstimateScreen()),
            ),
            QuickAction(
              icon: Icons.search,
              label: 'Find a part',
              onTap: _findPart,
            ),
            QuickAction(
              icon: Icons.center_focus_strong_outlined,
              label: 'Scan a part',
              onTap: () => _go(const ScanScreen()),
            ),
            QuickAction(
              icon: Icons.assignment_outlined,
              label: 'Jobs',
              onTap: () => setState(() => _tab = 1),
            ),
          ],
        ),
        SectionLabel('Up next', trailing: '${upNext.length} active'),
        if (upNext.isEmpty)
          const InfoCard(
            child: Text(
              'No accepted job right now. Accept a request in the Jobs tab.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final j in upNext.take(3))
          InfoCard(
            onTap: () => setState(() {
              _jobFilter = 'Active';
              _tab = 1;
            }),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    j.status == 'In progress'
                        ? Icons.handyman_outlined
                        : Icons.schedule,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${j.car} · ${j.clientName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${j.problem}\n${slotLabel(j.slot)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${formatDzd(j.price)}\nDZD',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        const SectionLabel('Next badge'),
        _nextBadgeTip(repo),
      ],
    );
  }

  Widget _nextBadgeTip(Repo repo) {
    final locked = repo.mechanicBadges().where((b) => !b.earned).toList();
    if (locked.isEmpty) {
      return const InfoCard(
        child: Text('All badges earned. Great work!'),
      );
    }
    final b = locked.first;
    return InfoCard(
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.star),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${b.title}: ${b.hint}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- jobs

  Widget _jobsTab(Repo repo) {
    final list = repo.jobsWithStatus(_statusesOf(_jobFilter));
    if (_jobFilter == 'Done') {
      list.sort((a, b) => (b.completedAt ?? b.slot).compareTo(a.completedAt ?? a.slot));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final f in const ['New', 'Active', 'Done', 'Declined'])
              ChoiceChip(
                label: Text(
                  '$f (${repo.jobsWithStatus(_statusesOf(f)).length})',
                ),
                selected: _jobFilter == f,
                onSelected: (_) => setState(() => _jobFilter = f),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Nothing here yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final j in list) _jobCard(repo, j),
      ],
    );
  }

  Set<String> _statusesOf(String filter) {
    switch (filter) {
      case 'New':
        return {'New'};
      case 'Active':
        return {'Accepted', 'In progress'};
      case 'Done':
        return {'Done'};
      default:
        return {'Declined'};
    }
  }

  int _stepOf(JobRequest j) => switch (j.status) {
        'Accepted' => 1,
        'In progress' => 2,
        'Done' => 3,
        _ => 0,
      };

  Widget _jobCard(Repo repo, JobRequest j) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  j.car,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (j.urgent)
                const Pill(
                  text: 'Urgent',
                  color: AppColors.danger,
                  background: AppColors.dangerBg,
                  icon: Icons.bolt,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${j.clientName} · ${j.distanceKm.toStringAsFixed(1)} km away',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(j.problem, style: const TextStyle(fontSize: 14.5, height: 1.35)),
          if (j.status == 'Accepted' ||
              j.status == 'In progress' ||
              j.status == 'Done') ...[
            const SizedBox(height: 10),
            PhotoStrip(
              paths: j.photos,
              onAdd: () => _addJobPhoto(repo, j),
              onRemove: (p) => repo.removeJobPhoto(j, p),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 15, color: AppColors.muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  j.status == 'Done' && j.completedAt != null
                      ? 'Finished ${formatDate(j.completedAt!)}'
                      : slotLabel(j.slot),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Text(
                '${formatDzd(j.price)} DZD',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (j.status != 'Declined') ...[
            const SizedBox(height: 14),
            JobStepBar(step: _stepOf(j)),
          ],
          const SizedBox(height: 12),
          _jobActions(repo, j),
        ],
      ),
    );
  }

  Widget _jobActions(Repo repo, JobRequest j) {
    switch (j.status) {
      case 'New':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  repo.declineJob(j);
                  _toast('Request declined');
                },
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  repo.acceptJob(j);
                  _toast('Accepted. ${j.clientName} will be told.');
                },
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case 'Accepted':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => repo.startJob(j),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start work'),
          ),
        );
      case 'In progress':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              repo.finishJob(j);
              _toast('Done. ${formatDzd(j.price)} DZD added to this week.');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            icon: const Icon(Icons.check),
            label: const Text('Mark as done'),
          ),
        );
      case 'Done':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 18, color: AppColors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '+${formatDzd(j.price)} DZD earned',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Pill(
                  text: j.paid ? 'Paid' : 'Not paid yet',
                  color: j.paid ? AppColors.green : AppColors.warn,
                  background: j.paid ? AppColors.greenBg : AppColors.warnBg,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _go(InvoiceScreen(job: j)),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Invoice'),
                ),
                TextButton(
                  onPressed: _newReport,
                  child: const Text('Write report'),
                ),
              ],
            ),
          ],
        );
      default:
        return const Text(
          'You declined this request.',
          style: TextStyle(color: AppColors.muted),
        );
    }
  }

  // ---------------------------------------------------------------- reports

  Widget _reportsTab(Repo repo) {
    final all = repo.reportsOf(Repo.myMechanicName);
    final q = _reportSearch.text.trim().toLowerCase();
    final mine = q.isEmpty
        ? all
        : all
            .where((r) =>
                '${r.title} ${r.car} ${r.problem} ${r.diagnosis}'
                    .toLowerCase()
                    .contains(q))
            .toList();
    final helpful = all.fold<int>(0, (a, r) => a + repo.helpfulCountFor(r));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.description_outlined,
                value: '${all.length}',
                label: 'Published',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.thumb_up_alt_outlined,
                value: '$helpful',
                label: 'Found helpful',
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reportSearch,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search my reports',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (all.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'You have not published a report yet.\nTap "New report" to write your first one. Clients find your reports when they search a problem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          )
        else if (mine.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No report matches your search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final r in mine) _reportCard(repo, r),
      ],
    );
  }

  Future<void> _confirmDelete(Repo repo, RepairReport r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: Text('"${r.title}" will no longer show to clients.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      repo.deleteReport(r);
      _toast('Report deleted');
    }
  }

  Widget _reportCard(Repo repo, RepairReport r) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, color: AppColors.muted),
                onPressed: () => _editReport(r),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                onPressed: () => _confirmDelete(repo, r),
              ),
            ],
          ),
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
          Row(
            children: [
              Text(
                '${formatDzd(r.cost)} DZD',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.thumb_up_alt_outlined,
                  size: 15, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${repo.helpfulCountFor(r)} found helpful',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- profile

  Widget _profileTab(Repo repo) {
    final mechanic = repo.mechanics.firstWhere((m) => m.id == Repo.myMechanicId);
    final user = AuthService.instance.currentUser.value;
    final reviews = repo.reviewsFor(Repo.myMechanicId);
    final avg = repo.averageStars(Repo.myMechanicId) ?? mechanic.rating;
    final reportsCount = repo.reportsOf(Repo.myMechanicName).length;
    final xp = repo.mechanicXp;
    final level = xp ~/ 100 + 1;
    final inLevel = (xp % 100) / 100;
    final badges = repo.mechanicBadges();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.teal,
                    child: Text(
                      mechanic.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.profile['garage'] ?? mechanic.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user?.profile['specialty'] ??
                              mechanic.specialties.join(', '),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (repo.mechanicPro)
                    const Pill(
                      text: 'PRO',
                      color: AppColors.warn,
                      background: AppColors.warnBg,
                      icon: Icons.workspace_premium,
                    ),
                ],
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
                '$reportsCount published reports · ${repo.jobsDoneCount} jobs done',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${mechanic.address} · ${mechanic.hours}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        InfoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$xp XP',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: inLevel,
                  minHeight: 10,
                  backgroundColor: AppColors.chipBg,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${100 - xp % 100} XP to level ${level + 1}. Reports give 30 XP, jobs 20 XP, reviews 10 XP.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SectionLabel('Badges'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [for (final b in badges) _badgeTile(b)],
        ),
        const SizedBox(height: 14),
        _proCard(repo),
        const SectionLabel('Services and prices'),
        InfoCard(
          child: Column(
            children: [
              for (final s in mechanic.services)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.name)),
                      Text(
                        'from ${formatDzd(s.priceFrom)} DZD',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionLabel('Client reviews'),
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

  Widget _badgeTile(MechanicBadge b) {
    final color = b.earned ? AppColors.teal : AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: b.earned ? Colors.white : AppColors.chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: b.earned ? AppColors.teal : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            b.earned ? Icons.emoji_events : Icons.lock_outline,
            color: b.earned ? AppColors.star : AppColors.muted,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            b.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            b.hint,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _proCard(Repo repo) {
    final pro = repo.mechanicPro;
    return InfoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                pro ? 'Pro plan is on' : 'Go Pro',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Appear as Featured at the top of the mechanics list, get a Pro '
            'badge and priority job requests. Demo only: nothing is charged.',
            style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: pro
                ? OutlinedButton(
                    onPressed: () => repo.setMechanicPro(false),
                    child: const Text('Switch off Pro (demo)'),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    onPressed: () {
                      repo.setMechanicPro(true);
                      _toast('Pro is on (demo). You are now Featured.');
                    },
                    child: const Text('Try Pro (demo)'),
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    const titles = ['Mechanic space', 'Jobs', 'My reports', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_tab],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) => switch (_tab) {
          0 => _dashboardTab(repo),
          1 => _jobsTab(repo),
          2 => _reportsTab(repo),
          _ => _profileTab(repo),
        },
      ),
      floatingActionButton: _tab == 2
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
