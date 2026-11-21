import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Dark base with slowly drifting cyan / violet / magenta glows and a faint
/// tech grid. Wrap a screen with it and give the inner Scaffold a transparent
/// background (or just use [AppScaffold]).
class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -150 + 70 * t,
                  left: -130 + 90 * t,
                  child: _glow(AppColors.teal, 400, 0.22),
                ),
                Positioned(
                  bottom: -170 + 80 * (1 - t),
                  right: -150 + 70 * t,
                  child: _glow(AppColors.orange, 440, 0.20),
                ),
                Positioned(
                  top: size.height * 0.42 - 60 * t,
                  left: size.width * 0.55 - 40 * t,
                  child: _glow(AppColors.magenta, 240, 0.08),
                ),
              ],
            );
          },
        ),
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
        widget.child,
      ],
    );
  }

  Widget _glow(Color color, double size, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

/// Scaffold on top of the aurora background. Use it for every screen.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

/// Fades and slides its child in. Give each item of a list a growing
/// [index] for a staggered entrance.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double dy;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 520),
    this.dy = 22,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 70 * index.clamp(0, 12));
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, dy * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

/// Small press-down scale effect for tappable things.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Pulsing dot, e.g. for "live" indicators.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, this.color = AppColors.green, this.size = 8});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35 + 0.4 * _c.value),
              blurRadius: 4 + 8 * _c.value,
              spreadRadius: 1 + 2 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  const NavItem(this.icon, this.label, {this.activeIcon});
}

/// Floating glass navigation bar. The selected item gets a neon pill that
/// expands to show its label.
class GlassNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  const GlassNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.neon : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? (item.activeIcon ?? item.icon) : item.icon,
                size: 22,
                color: selected ? AppColors.onNeon : AppColors.muted,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onNeon,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty / no-result state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          NeonIconBadge(icon: icon, size: 64, color: AppColors.orange),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Translucent "glass" card with a thin neon edge. Set [glow] to make it
/// shine (used for the best match / selected items).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? accent;
  final bool glow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 16,
    this.accent,
    this.glow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final edge = accent ?? AppColors.border;
    final shape = BorderRadius.circular(radius);
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: AppGradients.glass,
        borderRadius: shape,
        border: Border.all(color: edge.withValues(alpha: glow ? 0.9 : 0.55)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: (accent ?? AppColors.teal).withValues(alpha: 0.28),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return card;
  }
}

/// Primary call to action: cyan to violet gradient with a soft glow.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final bool expand;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.onNeon,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.onNeon),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.onNeon,
                ),
              ),
            ],
          );

    final button = Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: AppGradients.neon,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Center(child: content),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Text painted with the neon gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const GradientText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => AppGradients.neon.createShader(rect),
      child: Text(text, style: style),
    );
  }
}

/// Square icon tile with a tinted glow, used for categories and roles.
class NeonIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const NeonIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.teal,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Small pill, e.g. "LIVE", "OPEN", "BEST MATCH".
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.color = AppColors.teal,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with a neon bar in front of it.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.teal, AppColors.orange],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.ink,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
      ],
    );
  }
}
