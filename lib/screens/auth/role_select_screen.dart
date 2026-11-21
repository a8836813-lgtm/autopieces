import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/futuristic.dart';
import 'login_screen.dart';

/// First screen: "Who are you?" Each role has its own login and sign-up.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      title: 'Welcome to AutoPièces',
      subtitle: 'Choose how you want to use the app.',
      children: [
        for (final role in UserRole.values) _RoleCard(role: role),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.client => AppColors.teal,
      UserRole.mechanic => AppColors.orange,
      UserRole.shop => AppColors.magenta,
    };
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      accent: color,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
      ),
      child: Row(
        children: [
          NeonIconBadge(icon: role.icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I am a ${role.title.toLowerCase()}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(role.subtitle,
                    style:
                        const TextStyle(color: AppColors.muted, height: 1.3)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: color),
        ],
      ),
    );
  }
}
