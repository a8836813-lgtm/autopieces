import 'package:material_ui/material_ui.dart';

import 'screens/auth/role_select_screen.dart';
import 'theme.dart';

void main() => runApp(const AutoPiecesApp());

class AutoPiecesApp extends StatelessWidget {
  const AutoPiecesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoPièces',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RoleSelectScreen(),
    );
  }
}
