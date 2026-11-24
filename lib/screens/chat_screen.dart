import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../services/chat_service.dart';
import '../services/photo_picker.dart';
import '../theme.dart';

/// Opens a chat from a client to a mechanic or a shop.
/// [peerKind] is 'mechanic' or 'shop'. [initialText] pre-fills the box.
void openChat(
  BuildContext context, {
  required String peerKind,
  required String peerId,
  required String peerName,
  String initialText = '',
}) {
  final me = ChatIdentity.current();
  if (me == null || !me.isClient) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in as a client to send messages.')),
    );
    return;
  }
  final thread = ChatThread(
    clientRef: me.clientRef,
    clientName: me.clientName,
    peerKind: peerKind,
    peerId: peerId,
    peerName: peerName,
  );
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ChatScreen(thread: thread, initialText: initialText),
  ));
}

/// One conversation: bubbles, a text box, and a photo button.
class ChatScreen extends StatefulWidget {
  final ChatThread thread;
  final String initialText;

  const ChatScreen({super.key, required this.thread, this.initialText = ''});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  late final ChatIdentity _me;
  Timer? _timer;
  bool _loading = true;
  bool _sending = false;
  bool _polling = false;
  String? _problem;
  String? _photo;

  @override
  void initState() {
    super.initState();
    // The screen is only reachable when somebody is signed in.
    _me = ChatIdentity.current()!;
    _input.text = widget.initialText;
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int get _lastId => _messages.isEmpty ? 0 : _messages.last.id;

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final fresh = await _service.fetchMessages(widget.thread, _me,
          afterId: _lastId);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final add = fresh.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _messages.addAll(add);
        _problem = null;
        _loading = false;
      });
      if (add.isNotEmpty) {
        _toBottom();
        _service.refresh(); // update the unread badge
      }
    } on ChatException catch (e) {
      if (mounted) {
        setState(() {
          _problem = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _problem = 'Chat is not available right now.';
          _loading = false;
        });
      }
    } finally {
      _polling = false;
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _attach() async {
    final path = await PhotoPicker.pick(context);
    if (path != null && mounted) setState(() => _photo = path);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final photo = _photo;
    if ((text.isEmpty && photo == null) || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await _service.send(widget.thread, _me,
          body: text, photoPath: photo);
      if (!mounted) return;
      setState(() {
        if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
        _input.clear();
        _photo = null;
        _problem = null;
      });
      _toBottom();
      _service.refresh();
    } on ChatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message not sent. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.titleFor(_me),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            Text(
              t.peerKind == 'shop' ? 'Shop' : 'Mechanic',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_problem != null)
            Container(
              width: double.infinity,
              color: AppColors.warnBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_problem!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.warn)),
            ),
          Expanded(child: _list()),
          _composer(),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No messages yet. Say hello, or send a photo of the part.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _Bubble(
        message: _messages[i],
        mine: _messages[i].fromClient == _me.isClient,
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_photo != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_photo!),
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: InkWell(
                          onTap: () => setState(() => _photo = null),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.ink,
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Add a photo',
                  onPressed: _sending ? null : _attach,
                  icon: const Icon(Icons.add_a_photo_outlined,
                      color: AppColors.teal),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : IconButton.filled(
                        tooltip: 'Send',
                        onPressed: _send,
                        style: IconButton.styleFrom(
                            backgroundColor: AppColors.teal),
                        icon: const Icon(Icons.send, size: 20),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : AppColors.ink;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            border: mine ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.hasPhoto) _photo(context),
              if (message.body.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: message.hasPhoto ? 6 : 0),
                    child: Text(message.body,
                        style: TextStyle(fontSize: 15, color: fg)),
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_clock(message.time),
                      style: TextStyle(
                          fontSize: 11,
                          color: mine ? Colors.white70 : AppColors.muted)),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(message.read ? Icons.done_all : Icons.done,
                        size: 14, color: Colors.white70),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(BoxFit fit) {
    final err = Container(
      color: AppColors.chipBg,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
    );
    if (message.photoUrl != null) {
      return Image.network(message.photoUrl!,
          fit: fit, errorBuilder: (_, __, ___) => err);
    }
    return Image.file(File(message.localPath!),
        fit: fit, errorBuilder: (_, __, ___) => err);
  }

  Widget _photo(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: _image(BoxFit.contain)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 200, height: 150, child: _image(BoxFit.cover)),
      ),
    );
  }
}
