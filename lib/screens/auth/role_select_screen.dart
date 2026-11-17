import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/auth_widgets.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(role.icon, color: AppColors.teal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('I am a ${role.title.toLowerCase()}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(role.subtitle,
                          style: const TextStyle(
                              color: AppColors.muted, height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
