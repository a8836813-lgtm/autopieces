import 'package:material_ui/material_ui.dart';

import '../services/chat_service.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'mechanics_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

/// The client app: bottom navigation with Search, Mechanics, Saved and Profile.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final me = ChatIdentity.current();
    if (me != null) ChatService.instance.start(me, this);
  }

  @override
  void dispose() {
    ChatService.instance.stop(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      HomeScreen(),
      MechanicsScreen(),
      SavedScreen(),
      MessagesScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          const NavigationDestination(
            icon: Icon(Icons.build_outlined),
            label: 'Mechanics',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: ValueListenableBuilder<int>(
              valueListenable: ChatService.instance.unread,
              builder: (context, n, _) => Badge(
                isLabelVisible: n > 0,
                label: Text('$n'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
