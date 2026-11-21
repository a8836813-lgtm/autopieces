import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/scan_mode.dart';
import '../theme.dart';
import 'results_screen.dart';
import 'stock_edit_screen.dart';
import '../widgets/futuristic.dart';

/// Shows the top matches for the scanned part and lets the user confirm one.
class CandidatesScreen extends StatefulWidget {
  final List<MatchCandidate> candidates;
  final ScanMode mode;

  const CandidatesScreen({
    super.key,
    required this.candidates,
    required this.mode,
  });

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  int _selected = 0;

  void _confirm() {
    final part = widget.candidates[_selected].part;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.mode == ScanMode.client
            ? ResultsScreen(part: part)
            : StockEditScreen(part: part),
      ),
    );
  }

  void _noneOfThese() {
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name == '/shop',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.mode == ScanMode.client;
    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Is this your part?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'We compared your photos with the catalog.',
                    style: TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                ),
                for (var i = 0; i < widget.candidates.length; i++)
                  _candidateCard(i),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isClient ? 'Find shops with this part' : 'Check my stock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _noneOfThese,
                  child: const Text('None of these, go back'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateCard(int index) {
    final c = widget.candidates[index];
    final selected = index == _selected;
    final percent = (c.confidence * 100).round();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? AppColors.teal : AppColors.border,
        width: selected ? 2 : 1,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => setState(() => _selected = index),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? AppColors.teal : AppColors.muted,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    if (index == 0)
                      const Text(
                        'Best match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            index == 0 ? AppColors.greenBg : AppColors.chipBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: index == 0 ? AppColors.green : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.part.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'OEM ${c.part.oem} · ${c.part.fits}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  c.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
