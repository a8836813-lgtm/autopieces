import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import 'pill.dart';

/// A repair report. Collapsed it shows the headline facts (cost, time,
/// warranty); tapping expands the full problem, diagnosis and work done.
class ReportCard extends StatefulWidget {
  final RepairReport report;
  final int helpfulCount;
  final bool isHelpful;
  final VoidCallback onHelpful;

  /// When null the mechanic name is plain text (used on the mechanic's own page).
  final VoidCallback? onMechanicTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.helpfulCount,
    required this.isHelpful,
    required this.onHelpful,
    this.onMechanicTap,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _expanded = false;

  /// Parts as a list: the detailed list when present, else the text field.
  List<String> get _parts {
    final r = widget.report;
    if (r.partsUsed.isNotEmpty) return r.partsUsed;
    return r.parts
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  Widget _fact(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _section(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _costRow(String label, int value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${formatDzd(value)} DZD', style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.category.isNotEmpty || r.date.isNotEmpty) ...[
                  Row(
                    children: [
                      if (r.category.isNotEmpty)
                        Pill(
                          text: r.category,
                          color: AppColors.teal,
                          background: const Color(0xFF12324A),
                        ),
                      const Spacer(),
                      Text(
                        r.date,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${r.car} · ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    if (widget.onMechanicTap != null)
                      InkWell(
                        onTap: widget.onMechanicTap,
                        child: Text(
                          r.mechanicName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    else
                      Text(
                        r.mechanicName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _fact(Icons.payments_outlined, '${formatDzd(r.cost)} DZD'),
                    if (r.durationHours > 0)
                      _fact(Icons.schedule, formatDuration(r.durationHours)),
                    if (r.warrantyMonths > 0)
                      _fact(
                        Icons.shield_outlined,
                        '${r.warrantyMonths} mo warranty',
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _section('PROBLEM', r.problem),
                            _section('DIAGNOSIS', r.diagnosis),
                            _section('WORK DONE', r.workDone),
                            if (_parts.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'PARTS USED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final p in _parts) Pill(text: p),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 6),
                            if (r.laborCost + r.partsCost > 0) ...[
                              _costRow('Labor', r.laborCost),
                              _costRow('Parts', r.partsCost),
                            ],
                            _costRow('Total', r.cost, bold: true),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: widget.onHelpful,
                      icon: Icon(
                        widget.isHelpful
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 16,
                      ),
                      label: Text('Helpful · ${widget.helpfulCount}'),
                    ),
                    const Spacer(),
                    Text(
                      _expanded ? 'Hide details' : 'Show details',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.muted,
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
