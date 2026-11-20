import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Small rounded label used for badges, categories and status.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  const Pill({
    super.key,
    required this.text,
    this.color = AppColors.muted,
    this.background = AppColors.chipBg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
