import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme_mechanic.dart';

/// Card with a soft neon glow and a dark gradient background.
class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glow;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.glow = MechColors.cyan,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: glow.withAlpha(34), blurRadius: 22),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MechColors.surface2, MechColors.surface],
            ),
            border: Border.all(color: glow.withAlpha(90)),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Gradient button with a glow. Pass a null [onPressed] to disable it.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool expand;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = MechColors.cyan,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final base = enabled ? color : MechColors.border;
    final radius = BorderRadius.circular(14);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: 18,
              color: enabled ? MechColors.onNeon : MechColors.muted),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? MechColors.onNeon : MechColors.muted,
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled
            ? [BoxShadow(color: color.withAlpha(70), blurRadius: 16)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [base, base.withAlpha(185)],
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small status dot that pulses like a radar ping when [active].
class PulseDot extends StatefulWidget {
  final Color color;
  final bool active;
  final double size;

  const PulseDot({
    super.key,
    required this.color,
    this.active = true,
    this.size = 10,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 2.6;
    final color = widget.active ? widget.color : MechColors.muted;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.active ? _c.value : 0.0;
        final ring = widget.size * (1 + 1.6 * t);
        return SizedBox(
          width: box,
          height: box,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Container(
                  width: ring,
                  height: ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha((120 * (1 - t)).round()),
                  ),
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: widget.active
                      ? [BoxShadow(color: color.withAlpha(150), blurRadius: 8)]
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Number that counts up to [value] when it appears or changes.
class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String Function(int value)? format;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.round();
        return Text(format != null ? format!(n) : '$n', style: style);
      },
    );
  }
}

/// Circular gauge from 0 to 1 with an animated glowing arc.
class RingGauge extends StatelessWidget {
  final double value;
  final String centerText;
  final String label;
  final Color color;
  final double size;

  const RingGauge({
    super.key,
    required this.value,
    required this.centerText,
    required this.label,
    this.color = MechColors.cyan,
    this.size = 92,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _RingPainter(progress: v, color: color),
                child: Center(
                  child: Text(
                    centerText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: MechColors.text,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: MechColors.muted),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = (Offset.zero & size).deflate(stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = MechColors.border;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final sweep = math.pi * 2 * progress;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..color = color.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Smooth line chart with a gradient fill that draws itself in.
class Sparkline extends StatelessWidget {
  final List<int> values;
  final Color color;
  final double height;

  const Sparkline({
    super.key,
    required this.values,
    this.color = MechColors.cyan,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparkPainter(values: values, color: color, progress: t),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<int> values;
  final Color color;
  final double progress;

  _SparkPainter({
    required this.values,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const pad = 10.0;
    final maxV = values.fold<int>(1, (m, v) => math.max(m, v)).toDouble();
    final stepX = (size.width - pad * 2) / (values.length - 1);

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          pad + stepX * i,
          size.height - pad - (values[i] / maxV) * (size.height - pad * 2),
        ),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final cx = a.dx + (b.dx - a.dx) / 2;
      line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(90), color.withAlpha(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, Paint()..color = MechColors.bg);
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.values != values;
}

/// Page background: deep navy, a faint grid and two soft color glows.
class GridBackdrop extends StatelessWidget {
  final Widget child;
  const GridBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = MechColors.bg);

    void glow(Alignment center, Color c) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: center,
            radius: 0.85,
            colors: [c.withAlpha(46), c.withAlpha(0)],
          ).createShader(rect),
      );
    }

    glow(const Alignment(-1.0, -1.0), MechColors.cyan);
    glow(const Alignment(1.0, 0.9), MechColors.violet);

    final line = Paint()
      ..color = const Color(0x1422D3EE)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

/// "SECTION TITLE" with an optional action on the right.
class MechSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const MechSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: MechColors.cyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: MechColors.muted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Four-step progress for a job: requested, accepted, in progress, done.
class JobStepper extends StatelessWidget {
  final int step; // 0 to 3
  final Color color;

  const JobStepper({super.key, required this.step, this.color = MechColors.cyan});

  static const _labels = ['Requested', 'Accepted', 'Working', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= step ? color : MechColors.border,
                  boxShadow: i == step
                      ? [BoxShadow(color: color.withAlpha(150), blurRadius: 8)]
                      : null,
                ),
                child: i < step
                    ? const Icon(Icons.check,
                        size: 10, color: MechColors.onNeon)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10,
                  color: i <= step ? MechColors.text : MechColors.muted,
                ),
              ),
            ],
          ),
          if (i < 3)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: i < step ? color : MechColors.border,
              ),
            ),
        ],
      ],
    );
  }
}
