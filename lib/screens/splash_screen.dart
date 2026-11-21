import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/futuristic.dart';
import 'auth/role_select_screen.dart';

/// Animated intro: logo reveal, loading bar, then the role screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const RoleSelectScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: logo,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: AppGradients.neon,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.5),
                      blurRadius: 50,
                      spreadRadius: -6,
                    ),
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.4),
                      blurRadius: 60,
                      spreadRadius: -10,
                      offset: const Offset(20, 20),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_suggest_rounded,
                  size: 60,
                  color: AppColors.onNeon,
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: text,
              child: const Column(
                children: [
                  GradientText(
                    'AUTOPIÈCES',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'FIND ANY PART. INSTANTLY.',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 3,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 140,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _c.value,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
