import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ExploreGroupChatPanel extends StatefulWidget {
  const ExploreGroupChatPanel({super.key});

  @override
  State<ExploreGroupChatPanel> createState() => _ExploreGroupChatPanelState();
}

class _ExploreGroupChatPanelState extends State<ExploreGroupChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _pendingImage;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      senderName: 'Maude Hall',
      senderAvatarUrl: 'https://i.pravatar.cc/100?img=5',
      text: 'Morning, can I help you?',
      isMe: false,
      timeLabel: '09:31 am',
    ),
    _ChatMessage(
      senderName: 'Dianne Russell',
      senderAvatarUrl: 'https://i.pravatar.cc/100?img=32',
      text:
          'Sure! First, can you tell me about your daily routine and eating habits? That will help me suggest something suitable.',
      isMe: false,
      timeLabel: '09:33 am',
    ),
    _ChatMessage(
      senderName: 'You',
      senderAvatarUrl: 'https://i.pravatar.cc/100?img=47',
      text:
          'Hey! My body weight is increasing. I\'m gaining weight and want some suggestions.',
      isMe: true,
      timeLabel: '09:33 am',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pendingImage = bytes;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          senderName: 'You',
          senderAvatarUrl: 'https://i.pravatar.cc/100?img=47',
          text: text,
          isMe: true,
          timeLabel: 'Now',
          imageBytes: _pendingImage,
        ),
      );
      _messageController.clear();
      _pendingImage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _messages.length,
                separatorBuilder: (_, separatorIndex) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _pendingImage!,
                        height: 80,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton(
                        onPressed: () => setState(() => _pendingImage = null),
                        icon: const Icon(Icons.cancel, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onTap: _scrollToLatest,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Write your message',
                          prefixIcon: IconButton(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.attach_file),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCDCDC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCDCDC),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 54,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _sendMessage,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final String url;

  const _HeaderAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFEAEAEA),
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 16),
          ),
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF21C45D),
        shape: BoxShape.circle,
      ),
    );
  }
}

class ExploreChatHeaderInfo extends StatelessWidget {
  final VoidCallback onInviteTap;

  const ExploreChatHeaderInfo({super.key, required this.onInviteTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          height: 35,
          child: Stack(
            children: const [
              Positioned(
                left: 0,
                child: _HeaderAvatar(url: 'https://i.pravatar.cc/100?img=5'),
              ),
              Positioned(
                left: 24,
                child: _HeaderAvatar(url: 'https://i.pravatar.cc/100?img=32'),
              ),
              Positioned(
                left: 48,
                child: _HeaderAvatar(url: 'https://i.pravatar.cc/100?img=47'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maude Hall Room',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1),
              Row(
                children: [
                  _OnlineDot(),
                  SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (value) {
            if (value == 'invite') onInviteTap();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'invite',
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 101,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Invite',
                  style: TextStyle(fontSize: 28 / 2, color: Color(0xFF5A5A5A)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isMe ? const Color(0xFFDCF2DC) : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: message.isMe
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!message.isMe)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _HeaderAvatar(url: message.senderAvatarUrl),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Column(
            crossAxisAlignment: message.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!message.isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    if (message.imageBytes != null) ...[
                      if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          message.imageBytes!,
                          width: 150,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message.timeLabel,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final bool isMe;
  final String timeLabel;
  final Uint8List? imageBytes;

  _ChatMessage({
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.isMe,
    required this.timeLabel,
    this.imageBytes,
  });
}
