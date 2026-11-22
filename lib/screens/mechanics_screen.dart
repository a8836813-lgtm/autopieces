import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/mechanic_card.dart';
import '../widgets/report_card.dart';
import 'mechanic_detail_screen.dart';
import 'mechanics_map_screen.dart';

/// Mechanics directory and searchable repair reports.
class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});

  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  final TextEditingController _mCtrl = TextEditingController();
  final TextEditingController _rCtrl = TextEditingController();

  int _tab = 0; // 0 = mechanics, 1 = repair reports
  String _mQuery = '';
  String _rQuery = '';
  String? _mCategory;
  String? _rCategory;
  bool _verifiedOnly = false;
  bool _openNowOnly = false;
  MechanicSort _mSort = MechanicSort.topRated;
  ReportSort _rSort = ReportSort.mostHelpful;

  @override
  void dispose() {
    _mCtrl.dispose();
    _rCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      );

  Widget _searchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border,
        enabledBorder: _border,
      ),
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _categoryChips(String? selected, ValueChanged<String?> onSelected) {
    return _chipRow([
      ChoiceChip(
        label: const Text('All'),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
      ),
      for (final c in Repo.categories)
        ChoiceChip(
          label: Text(c),
          selected: selected == c,
          onSelected: (_) => onSelected(selected == c ? null : c),
        ),
    ]);
  }

  Widget _count(int n, String singular, String plural) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Text(
        '$n ${n == 1 ? singular : plural}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _empty(String message, VoidCallback onClear) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 40, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    );
  }

  void _openMechanic(Mechanic m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MechanicDetailScreen(mechanic: m),
      ),
    );
  }

  // ------------------------------------------------------------ mechanics

  Widget _requestsCard(Repo repo) {
    final active =
        repo.appointments.where((a) => a.status != 'Cancelled').toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your appointment requests',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
          for (final a in active)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${a.mechanic.name} · ${a.service}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${formatDate(a.when)} at ${formatTime(a.when)} · Waiting for confirmation',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => repo.cancelAppointment(a),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _mechanicsTab(Repo repo) {
    final list = repo.searchMechanics(
      query: _mQuery,
      category: _mCategory,
      verifiedOnly: _verifiedOnly,
      openNowOnly: _openNowOnly,
      sort: _mSort,
    );
    return [
      _requestsCard(repo),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const MechanicsMapScreen(),
        )),
        icon: const Icon(Icons.map_outlined),
        label: const Text('Mechanics near me on the map'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: AppColors.orange,
        ),
      ),
      const SizedBox(height: 16),
      _searchField(
        controller: _mCtrl,
        hint: 'Search by name, skill or service',
        onChanged: (v) => setState(() => _mQuery = v),
      ),
      const SizedBox(height: 12),
      _categoryChips(_mCategory, (c) => setState(() => _mCategory = c)),
      const SizedBox(height: 4),
      _chipRow([
        FilterChip(
          label: const Text('Verified'),
          avatar: const Icon(Icons.verified, size: 16),
          selected: _verifiedOnly,
          onSelected: (v) => setState(() => _verifiedOnly = v),
        ),
        FilterChip(
          label: const Text('Open now'),
          selected: _openNowOnly,
          onSelected: (v) => setState(() => _openNowOnly = v),
        ),
        ChoiceChip(
          label: const Text('Top rated'),
          selected: _mSort == MechanicSort.topRated,
          onSelected: (_) => setState(() => _mSort = MechanicSort.topRated),
        ),
        ChoiceChip(
          label: const Text('Nearest'),
          selected: _mSort == MechanicSort.nearest,
          onSelected: (_) => setState(() => _mSort = MechanicSort.nearest),
        ),
        ChoiceChip(
          label: const Text('Most reports'),
          selected: _mSort == MechanicSort.mostReports,
          onSelected: (_) => setState(() => _mSort = MechanicSort.mostReports),
        ),
      ]),
      _count(list.length, 'mechanic', 'mechanics'),
      if (list.isEmpty)
        _empty('No mechanic matches these filters.', () {
          _mCtrl.clear();
          setState(() {
            _mQuery = '';
            _mCategory = null;
            _verifiedOnly = false;
            _openNowOnly = false;
          });
        }),
      for (final m in list)
        MechanicCard(
          mechanic: m,
          reportsCount: repo.reportsCountFor(m.id),
          onTap: () => _openMechanic(m),
          onCall: () => callMechanic(context, m),
          onBook: () => showAppointmentSheet(context, m),
        ),
    ];
  }

  // -------------------------------------------------------------- reports

  List<Widget> _reportsTab(Repo repo) {
    final list = repo.searchReports(
      _rQuery,
      category: _rCategory,
      sort: _rSort,
    );
    return [
      const SizedBox(height: 16),
      const Text(
        'Search real problems that mechanics already fixed, with the real cost.',
        style: TextStyle(fontSize: 14, color: AppColors.muted),
      ),
      const SizedBox(height: 12),
      _searchField(
        controller: _rCtrl,
        hint: 'Describe a problem, e.g. grinding noise',
        onChanged: (v) => setState(() => _rQuery = v),
      ),
      const SizedBox(height: 12),
      _categoryChips(_rCategory, (c) => setState(() => _rCategory = c)),
      const SizedBox(height: 4),
      _chipRow([
        ChoiceChip(
          label: const Text('Most helpful'),
          selected: _rSort == ReportSort.mostHelpful,
          onSelected: (_) => setState(() => _rSort = ReportSort.mostHelpful),
        ),
        ChoiceChip(
          label: const Text('Lowest cost'),
          selected: _rSort == ReportSort.lowestCost,
          onSelected: (_) => setState(() => _rSort = ReportSort.lowestCost),
        ),
        ChoiceChip(
          label: const Text('Fastest fix'),
          selected: _rSort == ReportSort.fastest,
          onSelected: (_) => setState(() => _rSort = ReportSort.fastest),
        ),
      ]),
      _count(list.length, 'report', 'reports'),
      if (list.isEmpty)
        _empty('No report matches this problem yet.', () {
          _rCtrl.clear();
          setState(() {
            _rQuery = '';
            _rCategory = null;
          });
        }),
      for (final r in list)
        ReportCard(
          key: ValueKey(r.id),
          report: r,
          helpfulCount: repo.helpfulCountFor(r),
          isHelpful: repo.isHelpful(r.key),
          onHelpful: () => repo.toggleHelpful(r.key),
          onMechanicTap: () => _openMechanic(repo.mechanicById(r.mechanicId)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Repo.instance,
      builder: (context, _) {
        final repo = Repo.instance;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const Text(
              'Mechanics near Jijel',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    icon: Icon(Icons.build_outlined),
                    label: Text('Mechanics'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: Icon(Icons.description_outlined),
                    label: Text('Repair reports'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
            ...(_tab == 0 ? _mechanicsTab(repo) : _reportsTab(repo)),
          ],
        );
      },
    );
  }
}
