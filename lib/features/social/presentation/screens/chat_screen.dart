import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMine;

  const ChatMessage({required this.senderId, required this.text, required this.sentAt, required this.isMine});
}

/// Écran de chat 1-to-1. Les messages passent par
/// `chats/{chatId}/messages` (voir SCHEMA.md) avec une limite de
/// longueur appliquée aussi bien côté client que côté règles Firestore.
class ChatScreen extends StatefulWidget {
  final String friendDisplayName;
  final List<ChatMessage> messages;
  final void Function(String text) onSendMessage;

  const ChatScreen({
    super.key,
    required this.friendDisplayName,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();

  static const _quickEmojis = ['👍', '🎯', '🔥', '😂', '😮', '👏'];

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: Text(widget.friendDisplayName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[widget.messages.length - 1 - index];
                return Align(
                  alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: message.isMine ? AppColors.electricBlue : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.text, style: const TextStyle(color: AppColors.white)),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _quickEmojis
                  .map((emoji) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => widget.onSendMessage(emoji),
                          child: Text(emoji, style: const TextStyle(fontSize: 26)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: AppColors.white),
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: const TextStyle(color: AppColors.lightGray),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.electricBlue,
                  child: IconButton(icon: const Icon(Icons.send, color: AppColors.white, size: 18), onPressed: _send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
