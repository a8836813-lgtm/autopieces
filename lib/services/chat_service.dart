import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/repo.dart';
import 'auth_service.dart';

/// Who is using the chat right now and which side of a conversation they are.
///
/// A conversation is always between ONE client (identified by e-mail) and ONE
/// mechanic or shop (kind + id used by the app, e.g. mechanic m1 / shop s1).
class ChatIdentity {
  final bool isClient;
  final String clientRef;
  final String clientName;

  /// 'mechanic' or 'shop'. Only set for mechanic and shop accounts.
  final String? peerKind;
  final String? peerId;
  final String? peerName;

  const ChatIdentity._({
    required this.isClient,
    this.clientRef = '',
    this.clientName = '',
    this.peerKind,
    this.peerId,
    this.peerName,
  });

  /// The signed-in user, or null when nobody is signed in.
  static ChatIdentity? current() {
    final u = AuthService.instance.currentUser.value;
    if (u == null) return null;
    switch (u.role) {
      case UserRole.client:
        return ChatIdentity._(
          isClient: true,
          clientRef: u.email,
          clientName: u.name,
        );
      case UserRole.mechanic:
        return ChatIdentity._(
          isClient: false,
          peerKind: 'mechanic',
          peerId: Repo.myMechanicId,
          peerName: Repo.myMechanicName,
        );
      case UserRole.shop:
        return ChatIdentity._(
          isClient: false,
          peerKind: 'shop',
          peerId: Repo.myShopId,
          peerName: Repo.instance.shopById(Repo.myShopId).name,
        );
    }
  }

  String get key => isClient ? 'c:$clientRef' : 'p:$peerKind:$peerId';
}

class ChatMessage {
  final int id;
  final bool fromClient;
  final String body;

  /// Address of the photo on the server (php mode).
  final String? photoUrl;

  /// Path of the photo on this phone (demo mode).
  final String? localPath;
  final DateTime time;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.fromClient,
    required this.body,
    required this.time,
    this.photoUrl,
    this.localPath,
    this.read = false,
  });

  bool get hasPhoto => photoUrl != null || localPath != null;

  /// Text for the inbox line.
  String get preview => body.isNotEmpty ? body : 'Photo';
}

class ChatThread {
  final String clientRef;
  final String clientName;
  final String peerKind;
  final String peerId;
  final String peerName;
  final ChatMessage? last;
  final int unread;

  const ChatThread({
    required this.clientRef,
    required this.clientName,
    required this.peerKind,
    required this.peerId,
    required this.peerName,
    this.last,
    this.unread = 0,
  });

  String get key => '$clientRef|$peerKind|$peerId';

  /// Name of the other person, as seen by [me].
  String titleFor(ChatIdentity me) {
    final name = me.isClient ? peerName : clientName;
    if (name.trim().isNotEmpty) return name;
    return me.isClient ? 'Mechanic' : clientRef;
  }
}

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);
  @override
  String toString() => message;
}

/// Chat between clients and mechanics or shops.
///
/// Talks to the PHP/XAMPP server (php/chat/*.php) or, with CHAT_PHP=false,
/// keeps everything in memory. The screens only use this class.
abstract class ChatService {
  static final ChatService instance =
      AppConfig.chatViaPhp ? _PhpChatService() : _MemoryChatService();

  /// Total unread messages for the signed-in user (tab badge).
  final ValueNotifier<int> unread = ValueNotifier<int>(0);

  /// Conversations of the signed-in user, newest first.
  final ValueNotifier<List<ChatThread>> threads =
      ValueNotifier<List<ChatThread>>(const []);

  /// null = last request worked, otherwise a readable problem.
  final ValueNotifier<String?> problem = ValueNotifier<String?>(null);

  Timer? _timer;
  ChatIdentity? _me;
  Object? _owner;
  bool _busy = false;

  Future<List<ChatThread>> fetchInbox(ChatIdentity me);

  /// New messages of one conversation (id > [afterId]). Marks the other
  /// side's messages as read.
  Future<List<ChatMessage>> fetchMessages(
    ChatThread thread,
    ChatIdentity me, {
    int afterId = 0,
  });

  Future<ChatMessage> send(
    ChatThread thread,
    ChatIdentity me, {
    String body = '',
    String? photoPath,
  });

  /// Starts refreshing the inbox every few seconds for [me]. [owner] is the
  /// screen that asked, so an old screen closing cannot stop a newer one.
  void start(ChatIdentity me, Object owner) {
    _me = me;
    _owner = owner;
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  void stop(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _timer?.cancel();
    _timer = null;
    _me = null;
    threads.value = const [];
    unread.value = 0;
    problem.value = null;
  }

  Future<void> refresh() async {
    final me = _me;
    if (me == null || _busy) return;
    _busy = true;
    try {
      final list = await fetchInbox(me);
      if (_me?.key != me.key) return; // user changed meanwhile
      threads.value = list;
      unread.value = list.fold<int>(0, (a, t) => a + t.unread);
      problem.value = null;
    } on ChatException catch (e) {
      problem.value = e.message;
    } catch (_) {
      problem.value = 'Chat is not available right now.';
    } finally {
      _busy = false;
    }
  }
}

// ───────────────────────────── PHP / XAMPP ─────────────────────────────

class _PhpChatService extends ChatService {
  static const _offline =
      'Cannot reach the chat server. Start Apache and MySQL in XAMPP and '
      'check PHP_BASE_URL.';

  Future<Map<String, dynamic>> _getJson(
      String endpoint, Map<String, String> query) async {
    final uri = Uri.parse(ApiEndpoints.url(endpoint)).replace(
      queryParameters: query,
    );
    try {
      final res = await http.get(uri).timeout(AppConfig.requestTimeout);
      return _decode(res.body, res.statusCode);
    } on TimeoutException {
      throw const ChatException(_offline);
    } on http.ClientException {
      throw const ChatException(_offline);
    }
  }

  Map<String, dynamic> _decode(String body, int status) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ChatException(status == 404
          ? 'Chat files not found on the server. Copy the php folder to '
              'htdocs/autopieces/api.'
          : 'The chat server sent an unexpected answer (HTTP $status). '
              'Is the table chat_messages created?');
    }
    if (data['ok'] != true) {
      throw ChatException((data['error'] as String?) ?? 'Chat error.');
    }
    return data;
  }

  DateTime _time(String? s) =>
      DateTime.tryParse((s ?? '').replaceFirst(' ', 'T')) ?? DateTime.now();

  ChatMessage _message(Map<String, dynamic> m) {
    final photo = m['photo'] as String?;
    return ChatMessage(
      id: (m['id'] as num).toInt(),
      fromClient: m['sender'] == 'client',
      body: (m['body'] as String?) ?? '',
      time: _time(m['created_at'] as String?),
      read: m['read'] == true,
      photoUrl: photo == null ? null : ApiEndpoints.url(photo),
    );
  }

  @override
  Future<List<ChatThread>> fetchInbox(ChatIdentity me) async {
    final data = await _getJson(
      ApiEndpoints.chatInbox,
      me.isClient
          ? {'as': 'client', 'client_ref': me.clientRef}
          : {'as': 'peer', 'peer_kind': me.peerKind!, 'peer_id': me.peerId!},
    );
    return [
      for (final t in (data['threads'] as List).whereType<Map<String, dynamic>>())
        ChatThread(
          clientRef: t['client_ref'] as String,
          clientName: (t['client_name'] as String?) ?? '',
          peerKind: t['peer_kind'] as String,
          peerId: t['peer_id'] as String,
          peerName: (t['peer_name'] as String?) ?? '',
          last: _message(t['last'] as Map<String, dynamic>),
          unread: (t['unread'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    ChatThread thread,
    ChatIdentity me, {
    int afterId = 0,
  }) async {
    final data = await _getJson(ApiEndpoints.chatMessages, {
      'client_ref': thread.clientRef,
      'peer_kind': thread.peerKind,
      'peer_id': thread.peerId,
      'reader': me.isClient ? 'client' : 'peer',
      'after_id': '$afterId',
    });
    return [
      for (final m in (data['messages'] as List).whereType<Map<String, dynamic>>())
        _message(m),
    ];
  }

  @override
  Future<ChatMessage> send(
    ChatThread thread,
    ChatIdentity me, {
    String body = '',
    String? photoPath,
  }) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse(ApiEndpoints.url(ApiEndpoints.chatSend)))
      ..fields.addAll({
        'client_ref': thread.clientRef,
        'client_name': me.isClient ? me.clientName : thread.clientName,
        'peer_kind': thread.peerKind,
        'peer_id': thread.peerId,
        'peer_name': me.isClient ? thread.peerName : (me.peerName ?? ''),
        'sender': me.isClient ? 'client' : 'peer',
        'body': body,
      });
    if (photoPath != null) {
      req.files.add(await http.MultipartFile.fromPath('photo', photoPath));
    }
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final data = _decode(res.body, res.statusCode);
      return _message(data['message'] as Map<String, dynamic>);
    } on TimeoutException {
      throw const ChatException(_offline);
    } on http.ClientException {
      throw const ChatException(_offline);
    }
  }
}

// ───────────────────────────── In memory (demo) ─────────────────────────────

class _Stored {
  final ChatThread head; // names only
  final List<ChatMessage> messages = [];
  _Stored(this.head);
}

class _MemoryChatService extends ChatService {
  final Map<String, _Stored> _threads = {};
  int _nextId = 1;

  @override
  Future<List<ChatThread>> fetchInbox(ChatIdentity me) async {
    final out = <ChatThread>[];
    for (final s in _threads.values) {
      final h = s.head;
      final mine = me.isClient
          ? h.clientRef == me.clientRef
          : (h.peerKind == me.peerKind && h.peerId == me.peerId);
      if (!mine || s.messages.isEmpty) continue;
      final unread = s.messages
          .where((m) => m.fromClient != me.isClient && !m.read)
          .length;
      out.add(ChatThread(
        clientRef: h.clientRef,
        clientName: h.clientName,
        peerKind: h.peerKind,
        peerId: h.peerId,
        peerName: h.peerName,
        last: s.messages.last,
        unread: unread,
      ));
    }
    out.sort((a, b) => b.last!.id.compareTo(a.last!.id));
    return out;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    ChatThread thread,
    ChatIdentity me, {
    int afterId = 0,
  }) async {
    final s = _threads[thread.key];
    if (s == null) return const [];
    for (var i = 0; i < s.messages.length; i++) {
      final m = s.messages[i];
      if (m.fromClient != me.isClient && !m.read) {
        s.messages[i] = ChatMessage(
          id: m.id,
          fromClient: m.fromClient,
          body: m.body,
          time: m.time,
          localPath: m.localPath,
          read: true,
        );
      }
    }
    return s.messages.where((m) => m.id > afterId).toList();
  }

  @override
  Future<ChatMessage> send(
    ChatThread thread,
    ChatIdentity me, {
    String body = '',
    String? photoPath,
  }) async {
    final s = _threads.putIfAbsent(
      thread.key,
      () => _Stored(ChatThread(
        clientRef: thread.clientRef,
        clientName: me.isClient ? me.clientName : thread.clientName,
        peerKind: thread.peerKind,
        peerId: thread.peerId,
        peerName: me.isClient ? thread.peerName : (me.peerName ?? ''),
      )),
    );
    final m = ChatMessage(
      id: _nextId++,
      fromClient: me.isClient,
      body: body,
      time: DateTime.now(),
      localPath: photoPath,
    );
    s.messages.add(m);
    return m;
  }
}
