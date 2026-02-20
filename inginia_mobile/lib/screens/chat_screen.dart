import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';
import '../models/reservation_model.dart';
import '../repositories/chat_repository.dart';
import '../repositories/provider_repository.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';
import '../services/push_notification_service.dart';
import '../services/api_service.dart';
import '../widgets/voice_note_bubble.dart';

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
  final _providerRepository = ProviderRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  List<Message> _messages = [];
  bool _isLoading = true;
  int? _currentUserId;
  bool _isTyping = false;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  double _recordingDragOffset = 0.0;
  bool _isCancelled = false;
  bool _isUserHolding = false;
  bool _isSending = false;
  Reservation? _reservation;

  Timer? _typingTimer;
  Timer? _pollTimer;
  StreamSubscription? _notificationSubscription;

  final _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().user?.id;
    _fetchMessages();
    _fetchReservation();
    _initWebSocket();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchMessages(silent: true),
    );

    _notificationSubscription = PushNotificationService.messageStream.listen((
      data,
    ) {
      if (!mounted) return;
      final type = data['type'];
      if (type == 'chat' || type == 'new_message') {
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
    _recordTimer?.cancel();
    _notificationSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _fetchReservation() async {
    try {
      final res = await _providerRepository.getReservation(
        widget.reservationId,
      );
      if (mounted) {
        setState(() {
          _reservation = res;
        });
      }
    } catch (e) {
      print("Erreur fetch reservation: $e");
    }
  }

  void _initWebSocket() {
    _webSocketService.listenToChat(widget.reservationId, (data) {
      if (!mounted) return;
      final event = data['_event'];
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
          shouldScroll = true;
        }
        setState(() {
          // Utiliser un Set pour éviter absolument les doublons lors du polling
          final Set<int> existingIds = _messages.map((m) => m.id).toSet();
          for (var m in msgs) {
            if (!existingIds.contains(m.id)) {
              _messages.add(m);
              shouldScroll = true;
            }
          }
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
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        _isUserHolding = true;
        _isCancelled = false;
        _recordingDragOffset = 0;

        // Immédiatement montrer l'interface d'enregistrement pour la réactivité
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        HapticFeedback.mediumImpact();

        // Si l'utilisateur a relâché pendant l'initialisation du recorder
        if (!_isUserHolding) {
          _stopAndSendRecording();
          return;
        }

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission micro refusée")),
        );
      }
    } catch (e) {
      print("Erreur démarrage enregistrement: $e");
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopAndSendRecording({bool force = false}) async {
    _isUserHolding = false;
    if (!_isRecording && !force) return;

    _recordTimer?.cancel();
    _recordTimer = null;
    HapticFeedback.lightImpact();

    try {
      String? path;
      // On essaie d'arrêter le recorder quoi qu'il arrive
      try {
        path = await _audioRecorder.stop();
      } catch (e) {
        print("Erreur stop recorder: $e");
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      if (!_isCancelled && path != null) {
        await _sendAudioMessage(path);
      } else if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      print("Erreur globale arrêt: $e");
    } finally {
      // Sécurité absolue : on remet l'interface à zéro même si tout a planté
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isUserHolding = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _sendAudioMessage(String path) async {
    setState(() => _isSending = true);
    try {
      final newMessage = await _repository.sendMessage(
        widget.reservationId,
        null,
        audioPath: path,
      );
      if (mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.add(newMessage);
          }
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de l'envoi de l'audio: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _controller.clear();
    try {
      final newMessage = await _repository.sendMessage(
        widget.reservationId,
        text,
      );
      if (!_messages.any((m) => m.id == newMessage.id)) {
        setState(() {
          _messages.add(newMessage);
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
      }
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur d'envoi: $e")));
    }
  }

  String _getMediaUrl(String? path) {
    if (path == null) return "";
    if (path.startsWith('http')) return path;
    final apiBase = ApiService.baseUrl;
    final root = apiBase.replaceAll('/api', '');
    return '$root/storage/$path';
  }

  Future<void> _pickAndSendImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _isSending = true);
      try {
        final newMessage = await _repository.sendMessage(
          widget.reservationId,
          null,
          imagePath: image.path,
        );
        if (mounted) {
          setState(() {
            _messages.add(newMessage);
            _isSending = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur d'envoi d'image: $e")));
        }
      }
    }
  }

  Future<void> _showProposePriceDialog() async {
    final priceController = TextEditingController();
    final noteController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Proposer un prix',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Le client recevra votre proposition et pourra l\'accepter ou la refuser.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: 'F',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note (optionnel)',
                  hintText: 'Ex: Comprend les pièces et la main d\'œuvre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) return;
                  Navigator.pop(ctx);
                  setState(() => _isSending = true);
                  try {
                    final msg = await _repository.proposePrice(
                      widget.reservationId,
                      price,
                      note: noteController.text,
                    );
                    if (mounted) {
                      setState(() {
                        if (!_messages.any((m) => m.id == msg.id)) {
                          _messages.add(msg);
                        }
                        _isSending = false;
                      });
                      _scrollToBottom();
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isSending = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Envoyer la proposition'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respondToPrice(int messageId, String response) async {
    try {
      final result = await _repository.respondToPrice(messageId, response);
      // Reload messages to get updated status
      await _fetchMessages(silent: false);
      if (mounted && response == 'accepted') {
        final finalPrice = result['reservation']?['final_price'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prix de ${finalPrice ?? ''} F confirmé ! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCallChoices() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Passer un appel",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android, color: AppTheme.primary),
              ),
              title: const Text("Appel direct (GSM)"),
              subtitle: const Text("Utiliser l'application téléphone"),
              onTap: () {
                Navigator.pop(ctx);
                _makeDirectCall();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_call, color: Colors.green),
              ),
              title: const Text("Appel via l'application"),
              subtitle: const Text("Utiliser la connexion internet"),
              onTap: () {
                Navigator.pop(ctx);
                // Prochainement...
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bientôt disponible sur l'application"),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _makeDirectCall() async {
    if (_reservation == null) return;
    final isProvider = context.read<AuthProvider>().user?.role == 'prestataire';
    final number = isProvider
        ? _reservation!.clientPhone
        : _reservation!.providerPhone;

    if (number != null && number.isNotEmpty) {
      final Uri telUri = Uri.parse('tel:$number');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de lancer l'appel")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro de téléphone indisponible")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "En ligne",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _showCallChoices,
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
                    addSemanticIndexes: false,
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      final bool isLastInGroup =
                          index == _messages.length - 1 ||
                          _messages[index + 1].senderId != msg.senderId;
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
                        key: ValueKey(msg.id),
                        children: [
                          if (showDate) _buildDateSeparator(msg.createdAt),
                          _buildMessageBubble(msg, isMe, isLastInGroup),
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
          ExcludeSemantics(
            child:
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
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun message pour l'instant",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            "Entamez la conversation avec ${widget.otherUserName}",
            style: const TextStyle(color: Colors.black45, fontSize: 14),
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

  Widget _buildMessageBubble(Message msg, bool isMe, bool isLast) {
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
                if (msg.type == 'price_proposal') ...[
                  _buildPriceProposalBubble(msg, isMe),
                ] else ...[
                  if (msg.imageUrl != null) ...[
                    GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(_getMediaUrl(msg.imageUrl)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _getMediaUrl(msg.imageUrl),
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  if (msg.audioUrl != null)
                    VoiceNoteBubble(
                      audioUrl: _getMediaUrl(msg.audioUrl),
                      isMe: isMe,
                    ),
                  if (msg.content.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: msg.imageUrl != null || msg.audioUrl != null
                            ? 8
                            : 0,
                      ),
                      child: Text(
                        msg.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : const Color(0xFF333333),
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildPriceProposalBubble(Message msg, bool isMe) {
    final price = msg.proposedPrice ?? 0;
    final status = msg.priceStatus ?? 'pending';
    final isClient = !isMe;

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.hourglass_empty_rounded;
    String statusText = 'En attente de réponse...';
    if (status == 'accepted') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Accepté ✅';
    } else if (status == 'refused') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Refusé ❌';
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? Colors.white : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_rounded, color: statusColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Proposition de prix',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          Text(
            '${price.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1a1a2e),
            ),
          ),
          if (msg.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              msg.content,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          // Statut
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Boutons pour le client si pending
          if (isClient && status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToPrice(msg.id, 'refused'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToPrice(msg.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
        child: _isRecording ? _buildRecordingUI() : _buildNormalInputUI(),
      ),
    );
  }

  Widget _buildNormalInputUI() {
    final isProvider = context.read<AuthProvider>().user?.role == 'prestataire';
    return Row(
      children: [
        // Image picker
        IconButton(
          onPressed: () => _pickAndSendImage(),
          icon: Icon(
            Icons.image_outlined,
            color: AppTheme.primary.withOpacity(0.8),
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // Prix (prestataire seulement)
        if (isProvider) ...[
          const SizedBox(width: 6),
          IconButton(
            onPressed: _showProposePriceDialog,
            icon: const Icon(
              Icons.payments_outlined,
              color: Colors.green,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Proposer un prix',
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Votre message...",
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _controller.text.isEmpty
            ? Listener(
                onPointerDown: (_) => _startRecording(),
                onPointerUp: (_) => _stopAndSendRecording(),
                onPointerCancel: (_) => _stopAndSendRecording(),
                onPointerMove: (event) {
                  setState(() {
                    _recordingDragOffset = event.localPosition.dx;
                    if (_recordingDragOffset < -100) {
                      _isCancelled = true;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 20),
                ),
              )
            : _isSending
            ? const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Container(
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
    );
  }

  Widget _buildRecordingUI() {
    final bool isCritical = _isCancelled;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          ExcludeSemantics(
            child: const Icon(Icons.mic, color: Colors.red, size: 24)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 1.seconds,
                  color: Colors.red.withOpacity(0.3),
                )
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Opacity(
                opacity: (1 - (_recordingDragOffset.abs() / 100)).clamp(0, 1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _stopAndSendRecording(force: true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "STOP",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      isCritical
                          ? const Text(
                              "Relâcher",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chevron_left,
                                  color: Colors.grey.shade400,
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "Glisser",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ExcludeSemantics(
            child:
                Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? Colors.red.withOpacity(0.1)
                            : AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCritical ? Icons.delete_outline : Icons.mic,
                        color: isCritical ? Colors.red : AppTheme.primary,
                        size: 24,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 500.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                    ),
          ),
        ],
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
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              "En train d'écrire...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
