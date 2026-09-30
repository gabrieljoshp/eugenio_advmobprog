import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:eugenio_advmobprog/widgets/custom_text.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;

  bool _isSending = false;
  bool _hasMarkedSeen = false;
  Timestamp? _sendingStartedAt;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value!.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);

      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();

    final tappedUserFirstName = (widget.tappedUser['firstName'] ?? '')
        .toString();

    final tappedUserLastName = (widget.tappedUser['lastName'] ?? '').toString();

    final tappedUserName = '$tappedUserFirstName $tappedUserLastName'.trim();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: CustomText(
              text: tappedUserName.isNotEmpty ? tappedUserName : 'Unknown',
              fontSize: 25.sp,
            ),
          ),
          body: Column(
            children: [
              // Message
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    if (!_hasMarkedSeen && snapshot.hasData) {
                      _hasMarkedSeen = true;
                      chatService.markMessagesSeen(currentUserId, tappedUserId);
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;

                        final msgText = (data['message'] ?? '').toString();

                        final senderId = (data['senderId'] ?? '').toString();

                        final isMe = senderId == currentUserId;
                        final timestamp = data['timestamp'];
                        final isSending =
                            _isSending &&
                            isMe &&
                            _sendingStartedAt != null &&
                            timestamp is Timestamp &&
                            timestamp.compareTo(_sendingStartedAt!) >= 0;
                        final status = isSending
                            ? 'sending...'
                            : (data['status'] ?? 'sent').toString();

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(docs[index].id),
                          duration: const Duration(milliseconds: 280),
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                (isMe ? 18 : -18) * (1 - value),
                                0,
                              ),
                              child: child,
                            ),
                          ),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.5)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16)
                                    .copyWith(
                                      bottomLeft: isMe
                                          ? const Radius.circular(16)
                                          : Radius.zero,
                                      bottomRight: isMe
                                          ? Radius.zero
                                          : const Radius.circular(16),
                                    ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CustomText(
                                    text: msgText.isNotEmpty
                                        ? msgText
                                        : '[empty]',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.normal,
                                    textAlign: TextAlign.left,
                                  ),
                                  if (isMe)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomText(
                                          text: status,
                                          fontSize: 10.sp,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(width: 4.w),
                                        Icon(
                                          status == 'sent' ||
                                                  status == 'sending...'
                                              ? Icons.done
                                              : Icons.done_all,
                                          size: 14.sp,
                                          color: status == 'seen'
                                              ? Colors.blue
                                              : Colors.black54,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => !_isSending
                              ? _send(currentUserId, tappedUserId)
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Type a message ...',
                            hintStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () =>
                                  _send(currentUserId, tappedUserId),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
