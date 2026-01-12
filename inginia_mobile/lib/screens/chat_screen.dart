import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';
import '../services/push_notification_service.dart';

class ChatScreen extends StatefulWidget {
  final int reservationId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.reservationId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Message> _messages = [];
  bool _isLoading = true;
  int? _currentUserId;
  bool _isTyping = false; // Pour l'indicateur "en train d'écrire" interne
  Timer? _typingTimer;
  Timer? _pollTimer;
  StreamSubscription? _notificationSubscription;

  // Configuration WebSocket
  final _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().user?.id;
    _fetchMessages();
    _initWebSocket();
    // Fallback Polling (toutes les 5s) si le WebSocket échoue
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchMessages(silent: true),
    );

    // Listen to Foreground Notifications (FCM) via local stream
    _notificationSubscription = PushNotificationService.messageStream.listen((
      data,
    ) {
      if (!mounted) return;
      if (data['type'] == 'chat') {
        final resId = data['reservation_id'];
        if (resId != null &&
            resId.toString() == widget.reservationId.toString()) {
          _fetchMessages(silent: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _pollTimer?.cancel();
    _notificationSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    // On ne ferme pas le WebSocketService car il est global, mais on pourrait se désabonner
    super.dispose();
  }

  void _initWebSocket() {
    // S'abonner au canal de chat
    _webSocketService.listenToChat(widget.reservationId, (data) {
      if (!mounted) return;

      final event = data['_event'];

      // Nouveau message reçu (vérifie plusieurs possibilités de nommage)
      if (event == 'message.sent' ||
          event == '.message.sent' ||
          event == 'App\\Events\\MessageSent') {
        dynamic messageData = data['message'];
        if (messageData == null) messageData = data;

        try {
          final newMessage = Message.fromJson(messageData);
          if (!_messages.any((m) => m.id == newMessage.id)) {
            setState(() {
              _messages.add(newMessage);
              _isTyping = false;
            });
            _scrollToBottom();
          }
        } catch (e) {
          print("Erreur parsing message WebSocket: $e");
        }
      }

      // Indicateur de frappe (typing)
      if (event == 'client-typing') {
        setState(() {
          _isTyping = true;
        });
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isTyping = false);
        });
      }
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final msgs = await _repository.getMessages(widget.reservationId);
      if (mounted) {
        bool shouldScroll = false;
        if (_messages.length != msgs.length) {
          // New messages detected
          shouldScroll = true;
        }

        setState(() {
          _messages = msgs;
          _isLoading = false;
        });

        if (shouldScroll) _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60, // Marge extra
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    // UI Optimiste : Ajouter temporairement le message
    /*
    final tempMsg = Message(
      id: -1, // ID temporaire
      reservationId: widget.reservationId,
      senderId: _currentUserId ?? 0,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();
    */

    try {
      final newMessage = await _repository.sendMessage(
        widget.reservationId,
        text,
      );
      // Le WebSocket ajoutera le message confirmé, mais on l'ajoute ici pour l'instantanéité
      if (!_messages.any((m) => m.id == newMessage.id)) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur d'envoi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Implémenter l'upload d'image vers le backend via repository
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Envoi d'image bientôt disponible !")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Gris très clair style iOS
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0]
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16),
                ),
                const Text(
                  "En ligne", // TODO: Statut réel via WebSocket
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Action appel
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Infos mission
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }

                      final msg = _messages[index];
                      final isMe = msg.senderId == _currentUserId;

                      // Groupement des messages
                      final bool isFirstInGroup =
                          index == 0 ||
                          _messages[index - 1].senderId != msg.senderId;
                      final bool isLastInGroup =
                          index == _messages.length - 1 ||
                          _messages[index + 1].senderId != msg.senderId;

                      // Afficher la date si changement de jour ou > 1h
                      bool showDate = false;
                      if (index == 0) {
                        showDate = true;
                      } else {
                        final prevMsg = _messages[index - 1];
                        if (msg.createdAt
                                .difference(prevMsg.createdAt)
                                .inMinutes >
                            60) {
                          showDate = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(msg.createdAt),
                          _buildMessageBubble(
                            msg,
                            isMe,
                            isFirstInGroup,
                            isLastInGroup,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 56,
                  color: AppTheme.primary.withOpacity(0.3),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 24),
          Text(
            "Aucun message pour l'instant",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            "Entamez la conversation avec ${widget.otherUserName}",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "${date.day}/${date.month} à ${_formatTime(date)}",
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Message msg,
    bool isMe,
    bool isFirst,
    bool isLast,
  ) {
    return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: isLast ? 12 : 2,
              left: isMe ? 50 : 0,
              right: isMe ? 0 : 50,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : (isLast ? 4 : 18)),
                bottomRight: Radius.circular(isMe ? (isLast ? 4 : 18) : 18),
              ),
              boxShadow: [
                if (isLast)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF333333),
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                if (isLast) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ), // Lu
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _pickImage,
              icon: Icon(
                Icons.add_circle_outline,
                color: AppTheme.primary.withOpacity(0.8),
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Votre message...",
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (val) {
                    // Logic for typing indicator via WebSocket
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: widget.otherUserPhoto != null
                ? NetworkImage(widget.otherUserPhoto!)
                : null,
            child: widget.otherUserPhoto == null
                ? const Icon(Icons.person, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "En train d'écrire",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Row(
                  children: List.generate(3, (index) {
                    return Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(delay: (index * 200).ms, duration: 400.ms)
                        .then()
                        .fadeOut(duration: 400.ms);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
