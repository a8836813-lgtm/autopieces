import 'package:material_ui/material_ui.dart';

import '../widgets/futuristic.dart';
import 'home_screen.dart';
import 'mechanics_screen.dart';
import 'profile_screen.dart';

/// The client app: bottom navigation with Search, Mechanics and Profile.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      HomeScreen(),
      MechanicsScreen(),
      ProfileScreen(),
    ];
    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: GlassNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        items: const [
          NavItem(Icons.search, 'Search'),
          NavItem(Icons.build_outlined, 'Mechanics', activeIcon: Icons.build),
          NavItem(Icons.person_outline, 'Profile', activeIcon: Icons.person),
        ],
      ),
    );
  }
}
