import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});

  final AppUser? peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showEmojiPanel = false;
  final List<String> _quickEmojis = [
    '😀',
    '😃',
    '😅',
    '😍',
    '🤩',
    '😎',
    '🤔',
    '🙏',
    '🔥',
    '❤️',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(BuildContext ctx) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ctx.read<ChatCubit>().send(text);
    _messageController.clear();
    setState(() => _showEmojiPanel = false);
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    setState(() => _showEmojiPanel = false);
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    if (peer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(child: Text(context.l10n.userNotFound)),
      );
    }

    return BlocProvider(
      create: (_) => sl<ChatCubit>()..start(peer),
      child: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (prev, curr) =>
            prev.messages.length != curr.messages.length,
        listener: (context, state) {
          if (_scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            });
          }
        },
        builder: (context, state) {
          final title = peer.username.isNotEmpty ? peer.username : peer.email;
          return Scaffold(
            body: Stack(
              children: [
                // Ambient gradient background.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0f172a), Color(0xFF0a0f24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Glass header.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: LiquidGlass.withOwnLayer(
                        shape: const LiquidRoundedRectangle(borderRadius: 18),
                        settings: LiquidGlassSettings(
                          glassColor: Colors.white.withOpacity(0.12),
                          blur: 18,
                          thickness: 22,
                        ),
                        fake: true,
                        child: Container(
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  (peer.username.isNotEmpty
                                          ? peer.username[0]
                                          : peer.email[0])
                                      .toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      context.l10n.online,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Body with messages and input.
                Positioned.fill(
                  top: 88,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: [
                          Expanded(
                            child: LiquidGlass.withOwnLayer(
                              shape: const LiquidRoundedRectangle(
                                borderRadius: 20,
                              ),
                              settings: LiquidGlassSettings(
                                glassColor: Colors.white.withOpacity(0.08),
                                blur: 16,
                                thickness: 20,
                              ),
                              fake: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: _MessagesList(
                                  messages: state.messages,
                                  currentUserId: state.currentUserId,
                                  controller: _scrollController,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LiquidGlass.withOwnLayer(
                            shape: const LiquidRoundedRectangle(
                              borderRadius: 16,
                            ),
                            settings: LiquidGlassSettings(
                              glassColor: Colors.white.withOpacity(0.08),
                              blur: 14,
                              thickness: 18,
                            ),
                            fake: true,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.04),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _showEmojiPanel = !_showEmojiPanel,
                                    ),
                                    icon: const Icon(
                                      Icons.emoji_emotions_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.12),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        decoration: InputDecoration(
                                          hintText: context.l10n.inputHint,
                                          hintStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          border: InputBorder.none,
                                          isCollapsed: true,
                                          filled: true,
                                          fillColor: Colors.transparent,
                                        ),
                                        onSubmitted: (_) => _send(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _send(context),
                                    icon: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _showEmojiPanel
                        ? Container(
                            key: const ValueKey('emoji_panel'),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: _quickEmojis
                                  .map(
                                    (emoji) => GestureDetector(
                                      onTap: () => _insertEmoji(emoji),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.messages,
    required this.currentUserId,
    required this.controller,
  });

  final List<ChatMessage> messages;
  final String? currentUserId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noMessages,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.senderId == currentUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF4a6cf7).withOpacity(0.9)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isMine
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMine ? Colors.white : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
