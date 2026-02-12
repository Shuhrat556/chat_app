import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/utils/image_utils.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/home/presentation/cubit/users_cubit.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final UsersCubit _usersCubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usersCubit = sl<UsersCubit>()..start();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _usersCubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.user;
    final t = context.l10n;
    final locale = Localizations.localeOf(context);

    return BlocProvider<UsersCubit>.value(
      value: _usersCubit,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF010A1F), Color(0xFF03143A), Color(0xFF010A24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 6.h),
                  child: Row(
                    children: [
                      _AvatarWithPresence(
                        imageUrl: currentUser?.photoUrl,
                        fallback: _initialFromUser(currentUser),
                        isOnline: currentUser?.isOnline == true,
                        size: 62.w,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _headerTitle(locale, t),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 31.sp,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              currentUser?.isOnline == true
                                  ? t.online
                                  : t.offline,
                              style: TextStyle(
                                color: Color(0xFF00E47D),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/profile'),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Color(0xFFA57CFF),
                          size: 21.sp,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Color(0xFFA0ABC5),
                          size: 21.sp,
                        ),
                        color: const Color(0xFF0F1B36),
                        onSelected: (value) {
                          if (value == 'profile') {
                            context.push('/profile');
                          } else if (value == 'logout') {
                            context.read<AuthBloc>().add(
                              const SignOutRequested(),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Text(
                              t.profileTitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Text(
                              t.signOut,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 10.h),
                  child: Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13223F),
                      borderRadius: BorderRadius.circular(21.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 14.w),
                        Icon(
                          Icons.search,
                          color: Color(0xFF7382A3),
                          size: 23.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: _searchHint(locale),
                              hintStyle: TextStyle(
                                color: Color(0xFF6E7D9F),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              isCollapsed: true,
                              fillColor: Colors.transparent,
                              filled: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            onPressed: _searchController.clear,
                            icon: Icon(
                              Icons.close_rounded,
                              color: Color(0xFF8C97B2),
                              size: 19.sp,
                            ),
                          ),
                        SizedBox(width: 4.w),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 1.h,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: currentUser == null
                      ? Center(
                          child: Text(
                            t.notSignedIn,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : BlocBuilder<UsersCubit, UsersState>(
                          builder: (context, state) {
                            if (state.status == UsersStatus.loading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8D66FF),
                                ),
                              );
                            }

                            if (state.status == UsersStatus.error) {
                              return Center(
                                child: Text(
                                  state.error ?? t.error,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              );
                            }

                            final query = _searchController.text
                                .trim()
                                .toLowerCase();
                            final users =
                                state.users
                                    .where((u) => u.id != currentUser.id)
                                    .where((u) {
                                      if (query.isEmpty) return true;
                                      final fullText =
                                          [
                                                u.username,
                                                u.email,
                                                u.firstName,
                                                u.lastName,
                                                u.bio,
                                              ]
                                              .whereType<String>()
                                              .join(' ')
                                              .toLowerCase();
                                      return fullText.contains(query);
                                    })
                                    .toList()
                                  ..sort((a, b) {
                                    final aOnline = a.isOnline == true;
                                    final bOnline = b.isOnline == true;
                                    if (aOnline != bOnline) {
                                      return bOnline ? 1 : -1;
                                    }
                                    final aSeen =
                                        a.lastSeen ??
                                        DateTime.fromMillisecondsSinceEpoch(0);
                                    final bSeen =
                                        b.lastSeen ??
                                        DateTime.fromMillisecondsSinceEpoch(0);
                                    return bSeen.compareTo(aSeen);
                                  });

                            if (users.isEmpty) {
                              final message = query.isNotEmpty
                                  ? t.noUsers
                                  : t.noUsers;
                              return Center(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 18.h),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final peer = users[index];
                                final unread = peer.isOnline == true ? 1 : 0;
                                final previewText = _previewText(
                                  peer,
                                  t,
                                  locale,
                                );

                                return _ChatPreviewTile(
                                  peer: peer,
                                  preview: previewText,
                                  timeLabel: _timeLabel(peer.lastSeen, locale),
                                  unreadCount: unread,
                                  onTap: () => context.push(
                                    '/chat/${peer.id}',
                                    extra: peer,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initialFromUser(AppUser? user) {
    if (user == null) return 'U';
    final seed = user.username.isNotEmpty ? user.username : user.email;
    return seed.isEmpty ? 'U' : seed[0].toUpperCase();
  }

  String _searchHint(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Qidirish...',
      'ru' => 'Поиск...',
      'tg' => 'Ҷустуҷӯ...',
      _ => 'Search...',
    };
  }

  String _headerTitle(Locale locale, AppLocalizations t) {
    return switch (locale.languageCode) {
      'uz' => 'Xabarlar',
      _ => t.chatsTitle,
    };
  }

  String _nowLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Hozir',
      'ru' => 'Сейчас',
      'tg' => 'Ҳозир',
      _ => 'Now',
    };
  }

  String _timeLabel(DateTime? lastSeen, Locale locale) {
    if (lastSeen == null) return _nowLabel(locale);

    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 8) return _nowLabel(locale);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('HH:mm', locale.toLanguageTag()).format(lastSeen);
  }

  String _previewText(AppUser peer, AppLocalizations t, Locale locale) {
    final bio = peer.bio?.trim();
    if (bio != null && bio.isNotEmpty) return bio;

    if (peer.isOnline == true) {
      return switch (locale.languageCode) {
        'uz' => 'Onlayn',
        'ru' => 'Онлайн',
        'tg' => 'Онлайн',
        _ => t.online,
      };
    }

    final seen = peer.lastSeen;
    if (seen == null) return t.offline;

    final formatted = DateFormat('HH:mm', locale.toLanguageTag()).format(seen);
    return '${t.lastSeen}: $formatted';
  }
}

class _ChatPreviewTile extends StatelessWidget {
  const _ChatPreviewTile({
    required this.peer,
    required this.preview,
    required this.timeLabel,
    required this.unreadCount,
    required this.onTap,
  });

  final AppUser peer;
  final String preview;
  final String timeLabel;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final presenceColor = _presenceColor(peer);

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
        child: Row(
          children: [
            _AvatarWithPresence(
              imageUrl: peer.photoUrl,
              fallback: _initialFromPeer(peer),
              isOnline: true,
              size: 52.w,
              dotColor: presenceColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(peer),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? const Color(0xFFF1F5FF)
                          : const Color(0xFF9AA5BE),
                      fontSize: 13.sp,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: Color(0xFF7E89A8),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                if (unreadCount > 0)
                  Container(
                    width: 30.w,
                    height: 30.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7A2BFF), Color(0xFF9E4DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppUser user) {
    if (user.username.isNotEmpty) return user.username;
    return user.email;
  }

  String _initialFromPeer(AppUser user) {
    final seed = user.username.isNotEmpty ? user.username : user.email;
    return seed.isEmpty ? 'U' : seed[0].toUpperCase();
  }

  Color _presenceColor(AppUser user) {
    if (user.isOnline == true) return const Color(0xFF00D772);

    final lastSeen = user.lastSeen;
    if (lastSeen == null) return const Color(0xFF96A3BE);

    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes <= 10) return const Color(0xFFF0B200);
    return const Color(0xFF96A3BE);
  }
}

class _AvatarWithPresence extends StatelessWidget {
  const _AvatarWithPresence({
    required this.imageUrl,
    required this.fallback,
    required this.isOnline,
    required this.size,
    this.dotColor,
  });

  final String? imageUrl;
  final String fallback;
  final bool isOnline;
  final double size;
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
              border: Border.all(color: const Color(0xFF7457DB), width: 2.w),
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
          Positioned(
            right: -1.w,
            bottom: -1.h,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color:
                    dotColor ??
                    (isOnline
                        ? const Color(0xFF00D772)
                        : const Color(0xFF9AA3BA)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF031236),
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
