import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/utils/image_utils.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});

  final AppUser? peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  bool _showEmojiPanel = false;
  bool _hasTypedText = false;

  final List<String> _quickEmojis = const [
    '😀',
    '😁',
    '😅',
    '😍',
    '🤩',
    '😎',
    '🤔',
    '🙏',
    '🔥',
    '❤️',
    '🎉',
    '👍',
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasTypedText && mounted) {
      setState(() => _hasTypedText = hasText);
    }
  }

  void _send(BuildContext ctx) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ctx.read<ChatCubit>().send(text);
    _messageController.clear();

    if (_showEmojiPanel && mounted) {
      setState(() => _showEmojiPanel = false);
    }
  }

  void _toggleEmojiPanel() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmojiPanel = !_showEmojiPanel);
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

    if (mounted) {
      setState(() => _showEmojiPanel = false);
      _inputFocusNode.requestFocus();
    }
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

    final userStream = sl<UserRemoteDataSource>().streamUser(peer.id);
    final presenceStream = sl<PresenceRemoteDataSource>().watchPresence(
      peer.id,
    );

    return StreamBuilder<AppUser?>(
      stream: userStream,
      initialData: peer,
      builder: (context, userSnapshot) {
        final livePeer = userSnapshot.data ?? peer;
        final title = livePeer.username.isNotEmpty
            ? livePeer.username
            : livePeer.email;

        final l10n = context.l10n;
        final locale = Localizations.localeOf(context);

        return StreamBuilder<PresenceStatus>(
          stream: presenceStream,
          builder: (context, presenceSnapshot) {
            final presence = presenceSnapshot.data;

            return BlocProvider(
              create: (_) => sl<ChatCubit>()..start(livePeer),
              child: BlocConsumer<ChatCubit, ChatState>(
                listenWhen: (prev, curr) {
                  if (curr.messages.isEmpty) return false;
                  if (prev.messages.isEmpty) return true;
                  return prev.messages.last.id != curr.messages.last.id;
                },
                listener: (context, state) {
                  if (_scrollController.hasClients) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }
                },
                builder: (context, state) {
                  final me = context.watch<AuthBloc>().state.user;
                  final statusText = _statusText(
                    livePeer,
                    presence,
                    l10n,
                    locale,
                  );

                  return Scaffold(
                    body: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF020A1F),
                                  Color(0xFF04143A),
                                  Color(0xFF010A23),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -38.h,
                                  left: -84.w,
                                  child: Container(
                                    width: 228.w,
                                    height: 228.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(
                                            0xFF29437B,
                                          ).withValues(alpha: 0.30),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -108.h,
                                  right: -108.w,
                                  child: Container(
                                    width: 300.w,
                                    height: 300.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(
                                            0xFF1A2F63,
                                          ).withValues(alpha: 0.28),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            SafeArea(
                              bottom: false,
                              child: _ChatTopBar(
                                title: title,
                                statusText: statusText,
                                peer: livePeer,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  SizedBox(height: 8.h),
                                  _DayChip(label: _todayLabel(locale)),
                                  SizedBox(height: 5.h),
                                  Expanded(
                                    child: _MessagesList(
                                      messages: state.messages,
                                      currentUserId: state.currentUserId,
                                      controller: _scrollController,
                                      isLoadingMore: state.isLoadingMore,
                                      hasMore: state.hasMore,
                                      onReachTop: () =>
                                          context.read<ChatCubit>().loadOlder(),
                                      peerAvatarUrl: livePeer.photoUrl,
                                      myAvatarUrl: me?.photoUrl,
                                      myFallback: _fallbackInitial(me),
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _showEmojiPanel
                                        ? _EmojiPanel(
                                            key: const ValueKey('emoji_panel'),
                                            emojis: _quickEmojis,
                                            onTap: _insertEmoji,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  SafeArea(
                                    top: false,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        10.w,
                                        3.h,
                                        10.w,
                                        10.h,
                                      ),
                                      child: _ComposerBar(
                                        controller: _messageController,
                                        focusNode: _inputFocusNode,
                                        showSend: _hasTypedText,
                                        onSend: () => _send(context),
                                        onToggleEmoji: _toggleEmojiPanel,
                                        onInputTap: () {
                                          if (_showEmojiPanel) {
                                            setState(
                                              () => _showEmojiPanel = false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _fallbackInitial(AppUser? user) {
    if (user == null) return 'Y';
    final seed = user.username.isNotEmpty ? user.username : user.email;
    return seed.isEmpty ? 'Y' : seed[0].toUpperCase();
  }

  String _todayLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Bugun',
      'ru' => 'Сегодня',
      'tg' => 'Имрӯз',
      _ => 'Today',
    };
  }

  String _statusText(
    AppUser peer,
    PresenceStatus? presence,
    AppLocalizations t,
    Locale locale,
  ) {
    final effectiveOnline = presence?.isOnline ?? peer.isOnline == true;
    final lastSeen = presence?.lastSeen ?? peer.lastSeen;

    if (effectiveOnline) return t.online;
    if (lastSeen != null) {
      final formatted = DateFormat(
        'HH:mm, dd MMM',
        locale.toLanguageTag(),
      ).format(lastSeen);
      return '${t.lastSeen}: $formatted';
    }
    return t.offline;
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.title,
    required this.statusText,
    required this.peer,
  });

  final String title;
  final String statusText;
  final AppUser peer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 23.sp,
            ),
          ),
          _SmallAvatar(
            imageUrl: peer.photoUrl,
            fallback: _fallbackInitial(peer),
            size: 48.w,
            showDot: true,
            dotColor: const Color(0xFF00D772),
            borderColor: const Color(0xFF7457DB),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF00E47D),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.call_outlined,
              color: Color(0xFFA57CFF),
              size: 21.sp,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.videocam_outlined,
              color: Color(0xFFA57CFF),
              size: 21.sp,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: Color(0xFFA0ABC5), size: 21.sp),
          ),
        ],
      ),
    );
  }

  String _fallbackInitial(AppUser user) {
    final seed = user.username.isNotEmpty ? user.username : user.email;
    return seed.isEmpty ? 'U' : seed[0].toUpperCase();
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2946),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color(0xFF99A6C3),
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({required this.emojis, required this.onTap, super.key});

  final List<String> emojis;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 7.h),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A36),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Wrap(
        spacing: 7.w,
        runSpacing: 7.h,
        children: emojis
            .map(
              (emoji) => GestureDetector(
                onTap: () => onTap(emoji),
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(emoji, style: TextStyle(fontSize: 19.sp)),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.showSend,
    required this.onSend,
    required this.onToggleEmoji,
    required this.onInputTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showSend;
  final VoidCallback onSend;
  final VoidCallback onToggleEmoji;
  final VoidCallback onInputTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF08152F).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleEmoji,
            icon: Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: Color(0xFF9AA6C5),
              size: 24.sp,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.attach_file_rounded,
              color: Color(0xFF9AA6C5),
              size: 23.sp,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onTap: onInputTap,
              onSubmitted: (_) => onSend(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: const Color(0xFFA97DFF),
              decoration: InputDecoration(
                hintText: context.l10n.inputHint,
                hintStyle: TextStyle(
                  color: Color(0xFF7B89A7),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 11.h,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          IconButton(
            onPressed: showSend ? onSend : () {},
            icon: Icon(
              showSend ? Icons.send_rounded : Icons.mic_none_rounded,
              color: showSend
                  ? const Color(0xFFA57CFF)
                  : const Color(0xFF9AA6C5),
              size: 23.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.messages,
    required this.currentUserId,
    required this.controller,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onReachTop,
    required this.peerAvatarUrl,
    required this.myAvatarUrl,
    required this.myFallback,
  });

  final List<ChatMessage> messages;
  final String? currentUserId;
  final ScrollController controller;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onReachTop;
  final String? peerAvatarUrl;
  final String? myAvatarUrl;
  final String myFallback;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noMessages,
          style: TextStyle(
            color: Color(0xFF92A0BF),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final showTopLoader = hasMore || isLoadingMore;
    final headerCount = showTopLoader ? 1 : 0;

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels <= 140.h) {
          onReachTop();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        padding: EdgeInsets.fromLTRB(12.w, 3.h, 12.w, 11.h),
        itemCount: messages.length + headerCount,
        itemBuilder: (context, index) {
          if (showTopLoader && index == 0) {
            return SizedBox(
              height: 30.h,
              child: Center(
                child: isLoadingMore
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF9A72FF),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final message = messages[index - headerCount];
          final isMine = message.senderId == currentUserId;

          return _MessageBubble(
            message: message,
            isMine: isMine,
            peerAvatarUrl: peerAvatarUrl,
            myAvatarUrl: myAvatarUrl,
            myFallback: myFallback,
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.peerAvatarUrl,
    required this.myAvatarUrl,
    required this.myFallback,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerAvatarUrl;
  final String? myAvatarUrl;
  final String myFallback;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final timeText = DateFormat('HH:mm', localeTag).format(message.createdAt);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isMine ? null : const Color(0xFF182848),
        gradient: isMine
            ? const LinearGradient(
                colors: [Color(0xFF7A2FFF), Color(0xFFA610FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(isMine ? 20.r : 7.r),
          bottomRight: Radius.circular(isMine ? 7.r : 20.r),
        ),
        border: Border.all(
          color: isMine
              ? const Color(0xFF9C62FF).withValues(alpha: 0.60)
              : const Color(0xFF425980).withValues(alpha: 0.58),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          height: 1.24,
        ),
      ),
    );

    final metadata = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMine)
          _SmallAvatar(
            imageUrl: peerAvatarUrl,
            fallback: 'P',
            size: 21.w,
            showDot: false,
            borderColor: Colors.transparent,
          ),
        if (!isMine) SizedBox(width: 7.w),
        Text(
          timeText,
          style: TextStyle(
            color: Color(0xFF8190B0),
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isMine) SizedBox(width: 3.w),
        if (isMine)
          Icon(Icons.done_all_rounded, color: Color(0xFFA87EFF), size: 14.sp),
        if (isMine) SizedBox(width: 7.w),
        if (isMine)
          _SmallAvatar(
            imageUrl: myAvatarUrl,
            fallback: myFallback,
            size: 21.w,
            showDot: false,
            borderColor: Colors.transparent,
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            bubble,
            SizedBox(height: 4.h),
            metadata,
          ],
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({
    required this.imageUrl,
    required this.fallback,
    required this.size,
    required this.showDot,
    required this.borderColor,
    this.dotColor,
  });

  final String? imageUrl;
  final String fallback;
  final double size;
  final bool showDot;
  final Color borderColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final imageProvider = safeNetworkImage(imageUrl);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.8.w),
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: const Color(0xFF1A2745),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Text(
                      fallback,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: size * 0.38,
                      ),
                    )
                  : null,
            ),
          ),
          if (showDot)
            Positioned(
              right: -1.w,
              bottom: -1.h,
              child: Container(
                width: size * 0.30,
                height: size * 0.30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor ?? const Color(0xFF00D772),
                  border: Border.all(
                    color: const Color(0xFF041233),
                    width: 1.8.w,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
