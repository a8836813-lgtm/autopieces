import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../client_shell.dart';
import '../shop_shell.dart';
import 'role_select_screen.dart';

/// Decides which home screen a logged-in user sees.
///
/// Client goes to the existing [ClientShell].
/// Shop owners go to [ShopShell]. TODO: point [UserRole.mechanic] to the
/// mechanic dashboard once it exists.
Widget homeForUser(AppUser user) {
  switch (user.role) {
    case UserRole.client:
      return const ClientShell();
    case UserRole.mechanic:
      return RolePlaceholderScreen(
        user: user,
        title: 'Mechanic space',
        message: 'Next: publish repair reports and manage your profile.',
      );
    case UserRole.shop:
      return const ShopShell(isHome: true);
  }
}

/// Call this from the Profile screen "Log out" button.
void logoutToRoleSelect(BuildContext context) {
  AuthService.instance.logout();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
    (route) => false,
  );
}

class RolePlaceholderScreen extends StatelessWidget {
  final AppUser user;
  final String title;
  final String message;

  const RolePlaceholderScreen({
    super.key,
    required this.user,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => logoutToRoleSelect(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 56, color: AppColors.green),
              const SizedBox(height: 14),
              Text('Welcome, ${user.name}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(user.email, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
