import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});

  final AppUser? peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

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
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    if (peer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Foydalanuvchi topilmadi')),
      );
    }

    return BlocProvider(
      create: (_) => sl<ChatCubit>()..start(peer),
      child: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (prev, curr) => prev.messages.length != curr.messages.length,
        listener: (context, state) {
          // Scroll to bottom on new message.
          if (_scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            });
          }
        },
        builder: (context, state) {
          final title = peer.username.isNotEmpty ? peer.username : peer.email;
          return Scaffold(
            appBar: AppBar(title: Text('Chat: $title')),
            body: Column(
              children: [
                Expanded(
                  child: _MessagesList(
                    messages: state.messages,
                    currentUserId: state.currentUserId,
                    controller: _scrollController,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Xabar yozing...',
                          ),
                          onSubmitted: (_) => _send(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _send(context),
                        icon: const Icon(Icons.send),
                      ),
                    ],
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
      return const Center(child: Text('Hozircha xabarlar yo‘q'));
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
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isMine ? Colors.blue.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
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
