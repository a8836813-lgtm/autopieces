import 'package:material_ui/material_ui.dart';

import '../services/chat_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

/// List of conversations. Used as a tab (client) or a full page (mechanic,
/// shop owner).
class MessagesScreen extends StatelessWidget {
  /// true = opened as its own page with an app bar.
  final bool standalone;

  const MessagesScreen({super.key, this.standalone = false});

  String _when(DateTime t) {
    final now = DateTime.now();
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final service = ChatService.instance;
    final me = ChatIdentity.current();
    final body = me == null
        ? const Center(child: Text('Sign in to see your messages.'))
        : ListenableBuilder(
            listenable:
                Listenable.merge([service.threads, service.problem]),
            builder: (context, _) {
              final threads = service.threads.value;
              final problem = service.problem.value;
              return RefreshIndicator(
                onRefresh: service.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (problem != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warnBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(problem,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.warn)),
                      ),
                    if (threads.isEmpty && problem == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          me.isClient
                              ? 'No conversations yet.\nOpen a mechanic or a shop result and tap Chat.'
                              : 'No messages yet. Clients will write to you here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    for (final t in threads) _tile(context, t, me),
                  ],
                ),
              );
            },
          );
    if (!standalone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Messages',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: body,
    );
  }

  Widget _tile(BuildContext context, ChatThread t, ChatIdentity me) {
    final last = t.last;
    final unread = t.unread > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ChatScreen(thread: t),
          ));
          ChatService.instance.refresh();
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.chipBg,
          child: Icon(
            me.isClient
                ? (t.peerKind == 'shop'
                    ? Icons.storefront_outlined
                    : Icons.build_outlined)
                : Icons.person_outline,
            color: AppColors.teal,
          ),
        ),
        title: Text(t.titleFor(me),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
        subtitle: last == null
            ? null
            : Text(
                '${last.fromClient == me.isClient ? 'You: ' : ''}${last.preview}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: unread ? AppColors.ink : AppColors.muted)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (last != null)
              Text(_when(last.time),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.muted)),
            if (unread) ...[
              const SizedBox(height: 4),
              Badge(label: Text('${t.unread}')),
            ],
          ],
        ),
      ),
    );
  }
}

/// App bar button with the unread badge (mechanic and shop owner screens).
class MessagesAction extends StatelessWidget {
  const MessagesAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ChatService.instance.unread,
      builder: (context, n, _) => IconButton(
        tooltip: 'Messages',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const MessagesScreen(standalone: true),
        )),
        icon: Badge(
          isLabelVisible: n > 0,
          label: Text('$n'),
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}
