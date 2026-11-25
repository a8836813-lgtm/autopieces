import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import 'home_router.dart';
import 'role_select_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final Future<AppUser?> _restore = AuthService.instance.restore();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _restore,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AutoPièces',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        final user = snap.data;
        return user == null ? const RoleSelectScreen() : homeForUser(user);
      },
    );
  }
}
