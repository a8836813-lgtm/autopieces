import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/obd_codes.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/mechanic_widgets.dart';
import '../widgets/pill.dart';

/// Mechanic helper: look up an OBD-II trouble code and search the repair
/// reports by symptom. Rule-based demo, not a real scan tool.
class MechanicDiagnosticScreen extends StatefulWidget {
  const MechanicDiagnosticScreen({super.key});

  @override
  State<MechanicDiagnosticScreen> createState() =>
      _MechanicDiagnosticScreenState();
}

class _MechanicDiagnosticScreenState extends State<MechanicDiagnosticScreen> {
  final _code = TextEditingController();
  final _symptom = TextEditingController();
  ObdCode? _result;
  bool _searched = false;

  @override
  void dispose() {
    _code.dispose();
    _symptom.dispose();
    super.dispose();
  }

  void _lookup([String? value]) {
    if (value != null) _code.text = value;
    setState(() {
      _result = findObdCode(_code.text);
      _searched = _code.text.trim().isNotEmpty;
    });
  }

  Color _severityColor(String s) => switch (s) {
        'High' => AppColors.danger,
        'Medium' => AppColors.warn,
        _ => AppColors.green,
      };

  Color _severityBg(String s) => switch (s) {
        'High' => AppColors.dangerBg,
        'Medium' => AppColors.warnBg,
        _ => AppColors.greenBg,
      };

  Widget _codeResult() {
    if (!_searched) return const SizedBox.shrink();
    final r = _result;
    if (r == null) {
      return const InfoCard(
        child: Text(
          'This code is not in the demo list. Check the car maker manual for '
          'codes starting with P1, B, C or U.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
      );
    }
    final color = _severityColor(r.severity);
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Pill(
                text: '${r.severity} severity',
                color: color,
                background: _severityBg(r.severity),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Likely causes',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < r.causes.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.  ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Expanded(child: Text(r.causes[i])),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'First check: ${r.firstCheck}',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.green,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _similarReports() {
    final query = _symptom.text.trim();
    if (query.isEmpty) return const SizedBox.shrink();
    final List<RepairReport> found = Repo.instance.searchReports(query);
    if (found.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No published report matches. Try another word.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    return Column(
      children: [
        for (final r in found.take(5))
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.car} · ${r.mechanicName}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  r.diagnosis,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatDzd(r.cost)} DZD',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnose')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          const Text(
            'Type a trouble code from your scan tool, or describe the symptom. '
            'This is a quick helper with common codes, not a replacement for '
            'testing the car.',
            style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
          ),
          const SectionLabel('Trouble code (OBD-II)'),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: _lookup,
            decoration: InputDecoration(
              hintText: 'Example: P0420',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.memory),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _lookup,
              ),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in const ['P0300', 'P0420', 'P0171', 'P0562', 'P0299'])
                ActionChip(label: Text(c), onPressed: () => _lookup(c)),
            ],
          ),
          const SizedBox(height: 10),
          _codeResult(),
          const SectionLabel('Search repair reports by symptom'),
          TextField(
            controller: _symptom,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Example: brake noise, no start, overheating',
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
          const SizedBox(height: 10),
          _similarReports(),
        ],
      ),
    );
  }
}
