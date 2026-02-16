import 'dart:math' as math;

import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/utils/image_utils.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});

  final AppUser? peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  late final AnimationController _bgController;

  bool _showEmojiPanel = false;
  bool _hasTypedText = false;
  bool _isUploadingImage = false;
  bool _showScrollToBottom = false;
  bool _didInitialScrollToBottom = false;

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
    _scrollController.addListener(_handleScroll);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasTypedText && mounted) {
      setState(() => _hasTypedText = hasText);
    }

    // Typing indicator
    if (hasText) {
      context.read<ChatCubit>().onTypingStarted();
    } else {
      context.read<ChatCubit>().onTypingStopped();
    }
  }

  void _send(BuildContext ctx) {
    if (_isUploadingImage) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ctx.read<ChatCubit>().send(text);
    _messageController.clear();

    if (_showEmojiPanel && mounted) {
      setState(() => _showEmojiPanel = false);
    }
  }

  void _handleScroll() {
    _updateScrollToBottomVisibility();
  }

  void _updateScrollToBottomVisibility() {
    if (!_scrollController.hasClients || !mounted) return;
    final show = _distanceToBottom() > 220;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  double _distanceToBottom() {
    if (!_scrollController.hasClients) return 0;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    return (maxExtent - offset).clamp(0, double.infinity);
  }

  void _scrollToBottom({required bool animate}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
    _updateScrollToBottomVisibility();
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingImage) return;
    FocusScope.of(context).unfocus();

    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_imagePickError())));
      return;
    }

    if (picked == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await _uploadChatImage(picked);
      if (!mounted) return;

      final caption = _messageController.text.trim();
      await context.read<ChatCubit>().sendImage(
        imageUrl,
        caption: caption.isEmpty ? null : caption,
      );
      _messageController.clear();
      if (_showEmojiPanel) {
        setState(() => _showEmojiPanel = false);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_imageUploadError())));
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<String> _uploadChatImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = _extensionFromName(file.name);
    final fileId = const Uuid().v4();
    final ref = FirebaseStorage.instance.ref('chat_images/$fileId.$ext');
    final metadata = SettableMetadata(contentType: _mimeFromExtension(ext));
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _extensionFromName(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.png')) return 'png';
    if (normalized.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _mimeFromExtension(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  String _imagePickError() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Rasm tanlashda xatolik',
      'ru' => 'Ошибка при выборе изображения',
      'tg' => 'Хато ҳангоми интихоби тасвир',
      _ => 'Failed to pick image',
    };
  }

  String _imageUploadError() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Rasm yuborishda xatolik',
      'ru' => 'Ошибка при отправке изображения',
      'tg' => 'Хато ҳангоми ирсоли тасвир',
      _ => 'Failed to send image',
    };
  }

  String _uploadingImageLabel() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Rasm yuklanmoqda...',
      'ru' => 'Изображение загружается...',
      'tg' => 'Тасвир боргирӣ шуда истодааст...',
      _ => 'Uploading image...',
    };
  }

  Future<void> _makePhoneCall(AppUser peer) async {
    final phone = peer.phone?.trim() ?? '';
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_phoneMissingMessage())));
      return;
    }

    try {
      final uri = Uri(scheme: 'tel', path: phone);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_phoneLaunchError())));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_phoneLaunchError())));
    }
  }

  String _phoneMissingMessage() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Foydalanuvchi telefon raqami topilmadi',
      'ru' => 'Номер телефона пользователя не найден',
      'tg' => 'Рақами телефони корбар ёфт нашуд',
      _ => 'User phone number is not available',
    };
  }

  String _phoneLaunchError() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Qo‘ng‘iroqni ochib bo‘lmadi',
      'ru' => 'Не удалось открыть вызов',
      'tg' => 'Кушодани занг имкон надод',
      _ => 'Failed to start call',
    };
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_scrollController.hasClients ||
                        state.messages.isEmpty) {
                      return;
                    }

                    if (!_didInitialScrollToBottom) {
                      _didInitialScrollToBottom = true;
                      _scrollToBottom(animate: false);
                      return;
                    }

                    final isLatestMine =
                        state.messages.last.senderId == state.currentUserId;
                    final nearBottom = _distanceToBottom() < 120;
                    if (isLatestMine || nearBottom) {
                      _scrollToBottom(animate: true);
                    } else {
                      _updateScrollToBottomVisibility();
                    }
                  });
                },
                builder: (context, state) {
                  final statusText = _statusText(
                    livePeer,
                    presence,
                    state.isTyping,
                    l10n,
                    locale,
                  );

                  return Scaffold(
                    body: Stack(
                      children: [
                        Positioned.fill(
                          child: _AnimatedChatBackground(
                            controller: _bgController,
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
                                onCall: () => _makePhoneCall(livePeer),
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
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 160),
                                    child: _isUploadingImage
                                        ? Padding(
                                            key: const ValueKey(
                                              'image_upload_status',
                                            ),
                                            padding: EdgeInsets.fromLTRB(
                                              18.w,
                                              0,
                                              18.w,
                                              5.h,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 7.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F2142),
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.09),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 14.w,
                                                    height: 14.w,
                                                    child:
                                                        const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFFA57CFF,
                                                          ),
                                                        ),
                                                  ),
                                                  SizedBox(width: 9.w),
                                                  Text(
                                                    _uploadingImageLabel(),
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFFCBD8F6,
                                                      ),
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                                        onAttach: _pickAndSendImage,
                                        isUploadingImage: _isUploadingImage,
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
                        Positioned(
                          right: 14.w,
                          bottom: _showEmojiPanel ? 206.h : 120.h,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _showScrollToBottom ? 1 : 0,
                            child: IgnorePointer(
                              ignoring: !_showScrollToBottom,
                              child: _ScrollToBottomButton(
                                onTap: () => _scrollToBottom(animate: true),
                              ),
                            ),
                          ),
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
    bool isTyping,
    AppLocalizations t,
    Locale locale,
  ) {
    if (isTyping) {
      return 'yozmoqda...';
    }

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

class _AnimatedChatBackground extends StatelessWidget {
  const _AnimatedChatBackground({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final wave = math.sin(t * math.pi * 2);
        final pulse = (wave + 1) / 2;

        final start = Alignment(-1 + (0.18 * wave), -1);
        final end = Alignment(1 - (0.12 * wave), 1);

        final c1 = Color.lerp(
          const Color(0xFF020A1F),
          const Color(0xFF061A3E),
          pulse,
        )!;
        final c2 = Color.lerp(
          const Color(0xFF04143A),
          const Color(0xFF0A285B),
          1 - pulse,
        )!;
        final c3 = Color.lerp(
          const Color(0xFF010A23),
          const Color(0xFF04163B),
          pulse,
        )!;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c1, c2, c3],
              begin: start,
              end: end,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: (-40 + (14 * pulse)).h,
                left: (-84 + (18 * wave)).w,
                child: Container(
                  width: 230.w,
                  height: 230.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF2B4F91,
                        ).withValues(alpha: 0.18 + (0.14 * pulse)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: (-110 + (16 * pulse)).h,
                right: (-108 - (14 * wave)).w,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF1E3D7A,
                        ).withValues(alpha: 0.14 + (0.12 * (1 - pulse))),
                        Colors.transparent,
                      ],
                    ),
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

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.title,
    required this.statusText,
    required this.peer,
    required this.onCall,
  });

  final String title;
  final String statusText;
  final AppUser peer;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10274D).withValues(alpha: 0.96),
            const Color(0xFF0D2142).withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF8FB2FF).withValues(alpha: 0.24),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF020A1C).withValues(alpha: 0.42),
            blurRadius: 14.r,
            offset: Offset(0, 5.h),
          ),
        ],
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
            onPressed: onCall,
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
    required this.onAttach,
    required this.isUploadingImage,
    required this.onInputTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showSend;
  final VoidCallback onSend;
  final VoidCallback onToggleEmoji;
  final VoidCallback onAttach;
  final bool isUploadingImage;
  final VoidCallback onInputTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            decoration: BoxDecoration(
              color: const Color(0xFF091A39).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onToggleEmoji,
                  splashRadius: 20.r,
                  icon: Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: const Color(0xFF95A3C6),
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
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                    cursorColor: const Color(0xFFA97DFF),
                    decoration: InputDecoration(
                      hintText: context.l10n.inputHint,
                      hintStyle: TextStyle(
                        color: const Color(0xFF7E8DAF),
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                if (isUploadingImage)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFA57CFF),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: onAttach,
                    splashRadius: 20.r,
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: const Color(0xFF95A3C6),
                      size: 22.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: showSend ? null : const Color(0xFF15284E),
            gradient: showSend
                ? const LinearGradient(
                    colors: [Color(0xFF6D4CFF), Color(0xFF9E5CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: showSend
                  ? const Color(0xFFB490FF).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: IconButton(
            onPressed: showSend ? onSend : null,
            splashRadius: 22.r,
            icon: Icon(
              showSend ? Icons.send_rounded : Icons.mic_none_rounded,
              color: showSend ? Colors.white : const Color(0xFF95A3C6),
              size: 22.sp,
            ),
          ),
        ),
      ],
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
  });

  final List<ChatMessage> messages;
  final String? currentUserId;
  final ScrollController controller;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onReachTop;

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
        padding: EdgeInsets.fromLTRB(10.w, 2.h, 10.w, 9.h),
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

          return _MessageBubble(message: message, isMine: isMine);
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final timeText = DateFormat('HH:mm', localeTag).format(message.createdAt);
    final imageUrl = message.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final text = message.text.trim();
    final hasText = text.isNotEmpty;
    final bubblePadding = hasImage && !hasText
        ? EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h)
        : EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      padding: bubblePadding,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.network(
                imageUrl,
                width: MediaQuery.sizeOf(context).width * 0.68,
                height: 230.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: MediaQuery.sizeOf(context).width * 0.68,
                  height: 130.h,
                  color: const Color(0xFF1C2E51),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: const Color(0xFFA8B8DA),
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          if (hasImage && hasText) SizedBox(height: 8.h),
          if (hasText)
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
                height: 1.2,
              ),
            ),
        ],
      ),
    );

    final metadata = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeText,
          style: TextStyle(
            color: Color(0xFF8190B0),
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isMine) SizedBox(width: 3.w),
        if (isMine) _buildStatusIcon(message.status),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
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

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.schedule, color: Color(0xFF8190B0), size: 14.sp);
      case MessageStatus.sent:
        return Icon(Icons.done, color: Color(0xFF8190B0), size: 14.sp);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, color: Color(0xFF8190B0), size: 14.sp);
      case MessageStatus.read:
        return Icon(Icons.done_all, color: Color(0xFFA87EFF), size: 14.sp);
    }
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  const _ScrollToBottomButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Ink(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6F4DFF), Color(0xFF9D5BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFCCB1FF).withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3FD9).withValues(alpha: 0.42),
                blurRadius: 13.r,
                offset: Offset(0, 7.h),
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28.sp,
          ),
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
