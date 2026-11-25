import 'package:material_ui/material_ui.dart';

import 'screens/auth/start_screen.dart';
import 'services/notifier.dart';
import 'theme.dart';

void main() => runApp(const AutoPiecesApp());

class AutoPiecesApp extends StatelessWidget {
  const AutoPiecesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoPièces',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(),
      home: const StartScreen(),
    );
  }
}
