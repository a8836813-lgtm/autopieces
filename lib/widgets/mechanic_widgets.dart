import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../utils.dart';

/// White rounded card used across the mechanic space.
class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    );
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.white,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small bold heading above a group of cards.
class SectionLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// Number with a label and an icon, for the dashboard grid.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Seven bars (one per day) with the day name under each one.
class WeekBars extends StatelessWidget {
  /// Oldest day first, today last.
  final List<int> values;
  const WeekBars({super.key, required this.values});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (values[i] > 0)
                      Text(
                        '${(values[i] / 1000).toStringAsFixed(values[i] % 1000 == 0 ? 0 : 1)}k',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Container(
                      height: maxValue == 0
                          ? 4
                          : 4 + 72 * (values[i] / maxValue),
                      decoration: BoxDecoration(
                        color: i == values.length - 1
                            ? AppColors.orange
                            : AppColors.teal,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _days[today
                          .subtract(Duration(days: values.length - 1 - i))
                          .weekday - 1],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circle with a percentage in the middle.
class RateGauge extends StatelessWidget {
  /// 0 to 1.
  final double value;
  final String label;
  final String? centerText;
  final Color color;

  const RateGauge({
    super.key,
    required this.value,
    required this.label,
    this.centerText,
    this.color = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 7,
                  backgroundColor: AppColors.chipBg,
                  color: color,
                ),
              ),
              Text(
                centerText ?? '${(v * 100).round()}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Requested, Accepted, Working, Done as four dots joined by a line.
class JobStepBar extends StatelessWidget {
  /// 0 = Requested, 1 = Accepted, 2 = Working, 3 = Done.
  final int step;
  const JobStepBar({super.key, required this.step});

  static const _labels = ['Requested', 'Accepted', 'Working', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= step ? AppColors.teal : AppColors.chipBg,
                ),
                child: Icon(
                  i < step || step == 3 ? Icons.check : Icons.circle,
                  size: i < step || step == 3 ? 14 : 7,
                  color: i <= step ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: i == step ? FontWeight.w700 : FontWeight.w400,
                  color: i <= step ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
          if (i < _labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18, left: 2, right: 2),
                color: i < step ? AppColors.teal : AppColors.chipBg,
              ),
            ),
        ],
      ],
    );
  }
}

/// Square button with an icon, used for the quick actions.
class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    );
    return Material(
      color: Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Fri 21 Nov, 14:00" style label for a job slot.
String slotLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  final when = diff == 0
      ? 'Today'
      : diff == 1
          ? 'Tomorrow'
          : formatDate(d);
  return '$when, ${formatTime(d)}';
}
