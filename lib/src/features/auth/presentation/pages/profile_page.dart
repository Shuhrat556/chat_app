import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/core/utils/image_utils.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();

  AppUser? _lastSyncedUser;
  AuthStatus? _lastStatus;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _fillFromUser(context.read<AuthBloc>().state.user);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _photoUrlController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _fillFromUser(AppUser? user) {
    if (user == null) return;
    _lastSyncedUser = user;
    _usernameController.text = user.username;
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _birthDate = user.birthDate;
    _birthDateController.text = user.birthDate != null
        ? _formatDate(user.birthDate!)
        : '';
    _photoUrlController.text = user.photoUrl ?? '';
    _bioController.text = user.bio ?? '';
    _emailController.text = user.email;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate =
        _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected != null) {
      setState(() {
        _birthDate = selected;
        _birthDateController.text = _formatDate(selected);
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final rawPhotoUrl = _photoUrlController.text.trim();
    final photoUrl = safeNetworkImage(rawPhotoUrl) == null ? null : rawPhotoUrl;
    context.read<AuthBloc>().add(
      ProfileUpdateRequested(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        birthDate: _birthDate,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        photoUrl: photoUrl,
      ),
    );
  }

  void _confirmDelete(AppLocalizations t) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102041),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            t.deleteAccountTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          content: Text(
            t.deleteAccountBody,
            style: TextStyle(color: const Color(0xFFCCD6EE), fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                t.cancel,
                style: const TextStyle(color: Color(0xFFB0BCD8)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(const DeleteAccountRequested());
              },
              child: Text(
                t.confirm,
                style: const TextStyle(
                  color: Color(0xFFFF8F9D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF010A1F), Color(0xFF03143A), Color(0xFF010A24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.message != current.message ||
                previous.status != current.status ||
                previous.user != current.user,
            listener: (context, state) {
              final messenger = ScaffoldMessenger.of(context);
              if (state.user != null && state.user != _lastSyncedUser) {
                _fillFromUser(state.user);
              }
              if (state.status == AuthStatus.failure && state.message != null) {
                messenger.showSnackBar(SnackBar(content: Text(state.message!)));
              } else if (_lastStatus == AuthStatus.loading &&
                  state.status == AuthStatus.authenticated) {
                messenger.showSnackBar(
                  SnackBar(content: Text(t.profileUpdated)),
                );
              } else if (_lastStatus == AuthStatus.loading &&
                  state.status == AuthStatus.unauthenticated) {
                messenger.showSnackBar(
                  SnackBar(content: Text(t.accountDeleted)),
                );
              }
              _lastStatus = state.status;
            },
            builder: (context, state) {
              final user = state.user;
              final isBusy = state.status == AuthStatus.loading;

              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.notSignedIn,
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                      SizedBox(height: 10.h),
                      ElevatedButton(
                        onPressed: () => context.go('/auth'),
                        child: Text(t.signIn),
                      ),
                    ],
                  ),
                );
              }

              final compact = MediaQuery.sizeOf(context).width < 390;

              return Stack(
                children: [
                  Column(
                    children: [
                      _ProfileTopBar(
                        user: user,
                        title: t.profileTitle,
                        subtitle: t.profileSubtitle,
                        isBusy: isBusy,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 20.h),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 720.w),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _ProfileSectionCard(
                                      child: Row(
                                        children: [
                                          _ProfileAvatar(
                                            imageUrl: user.photoUrl,
                                            fallback: _avatarFallback(user),
                                            size: 53.w,
                                            showStatus: user.isOnline == true,
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.username.isNotEmpty
                                                      ? '@${user.username}'
                                                      : user.email,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                SizedBox(height: 3.h),
                                                Text(
                                                  user.email,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Color(0xFF97A4C4),
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    _ProfileSectionCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _ProfileInputField(
                                            controller: _usernameController,
                                            hint: t.username,
                                            icon: Icons.alternate_email,
                                            validator: (value) {
                                              final text = value?.trim() ?? '';
                                              if (text.isEmpty) {
                                                return t.requiredUsername;
                                              }
                                              if (text.length < 3) {
                                                return t.minUsername;
                                              }
                                              if (text.contains(' ')) {
                                                return t.noSpaces;
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 8.h),
                                          if (compact) ...[
                                            _ProfileInputField(
                                              controller: _firstNameController,
                                              hint: t.firstName,
                                              icon: Icons.badge,
                                            ),
                                            SizedBox(height: 8.h),
                                            _ProfileInputField(
                                              controller: _lastNameController,
                                              hint: t.lastName,
                                              icon: Icons.badge_outlined,
                                            ),
                                          ] else
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _ProfileInputField(
                                                    controller:
                                                        _firstNameController,
                                                    hint: t.firstName,
                                                    icon: Icons.badge,
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Expanded(
                                                  child: _ProfileInputField(
                                                    controller:
                                                        _lastNameController,
                                                    hint: t.lastName,
                                                    icon: Icons.badge_outlined,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          SizedBox(height: 8.h),
                                          if (compact) ...[
                                            _ProfileInputField(
                                              controller: _birthDateController,
                                              hint: t.birthDate,
                                              icon: Icons.cake,
                                              readOnly: true,
                                              onTap: _pickBirthDate,
                                              suffixIcon: Icon(
                                                Icons.calendar_today_outlined,
                                                color: Color(0xFF91A0C3),
                                                size: 18.sp,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            _ProfileInputField(
                                              controller: _photoUrlController,
                                              hint: t.photoUrl,
                                              icon: Icons.image_outlined,
                                              keyboardType: TextInputType.url,
                                            ),
                                          ] else
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _ProfileInputField(
                                                    controller:
                                                        _birthDateController,
                                                    hint: t.birthDate,
                                                    icon: Icons.cake,
                                                    readOnly: true,
                                                    onTap: _pickBirthDate,
                                                    suffixIcon: Icon(
                                                      Icons
                                                          .calendar_today_outlined,
                                                      color: Color(0xFF91A0C3),
                                                      size: 18.sp,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Expanded(
                                                  child: _ProfileInputField(
                                                    controller:
                                                        _photoUrlController,
                                                    hint: t.photoUrl,
                                                    icon: Icons.image_outlined,
                                                    keyboardType:
                                                        TextInputType.url,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          SizedBox(height: 8.h),
                                          _ProfileInputField(
                                            controller: _bioController,
                                            hint: t.bio,
                                            icon: Icons.info_outline,
                                            maxLines: 3,
                                          ),
                                          SizedBox(height: 8.h),
                                          _ProfileInputField(
                                            controller: _emailController,
                                            hint: t.email,
                                            icon: Icons.mail_outline,
                                            readOnly: true,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    _ProfilePrimaryButton(
                                      label: t.saveChanges,
                                      icon: Icons.save_outlined,
                                      onPressed: isBusy ? null : _submit,
                                      isLoading: isBusy,
                                    ),
                                    SizedBox(height: 10.h),
                                    _ProfileSectionCard(
                                      borderColor: const Color(0x44FF7D8E),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2C1631),
                                          Color(0xFF261534),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.deleteAccount,
                                            style: TextStyle(
                                              color: Color(0xFFFF9DAB),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 6.h),
                                          Text(
                                            t.deleteAccountBody,
                                            style: TextStyle(
                                              color: Color(0xFFCBAFC2),
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              height: 1.35,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: isBusy
                                                  ? null
                                                  : () => _confirmDelete(t),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFFFFB3BE,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0x66FF7D8E),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 11.h,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.delete_forever_outlined,
                                                size: 18.sp,
                                              ),
                                              label: Text(
                                                t.deleteAccount,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isBusy)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.40),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA06FFF),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _avatarFallback(AppUser user) {
    final seed = user.username.isNotEmpty ? user.username : user.email;
    return seed.isEmpty ? 'U' : seed[0].toUpperCase();
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.user,
    required this.title,
    required this.subtitle,
    required this.isBusy,
  });

  final AppUser user;
  final String title;
  final String subtitle;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 7.h, 8.w, 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isBusy ? null : () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 23.sp,
            ),
          ),
          _ProfileAvatar(
            imageUrl: user.photoUrl,
            fallback: _avatarFallback(user),
            size: 46.w,
            showStatus: user.isOnline == true,
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
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF00E47D),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: isBusy
                ? null
                : () => context.read<AuthBloc>().add(const SignOutRequested()),
            icon: Icon(
              Icons.logout,
              size: 16.sp,
              color: const Color(0xFFA57CFF),
            ),
            label: Text(
              t.signOut,
              style: TextStyle(
                color: Color(0xFFC7CEF0),
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _avatarFallback(AppUser user) {
    final seed = user.username.isNotEmpty ? user.username : user.email;
    return seed.isEmpty ? 'U' : seed[0].toUpperCase();
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.child,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
        ),
        gradient:
            gradient ??
            const LinearGradient(
              colors: [Color(0xFF102040), Color(0xFF0D1A36)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      ),
      child: child,
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.onTap,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onTap: onTap,
      style: TextStyle(
        color: readOnly ? const Color(0xFFB8C5E2) : Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Color(0xFF7C8AB0),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF96A5C8), size: 19.sp),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF132444),
        constraints: maxLines == 1 ? BoxConstraints(minHeight: 48.h) : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFA57CFF), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFFF8EA0)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFFF8EA0), width: 1.2),
        ),
      ),
    );
  }
}

class _ProfilePrimaryButton extends StatelessWidget {
  const _ProfilePrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF7A2BFF), Color(0xFFA610FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            padding: EdgeInsets.symmetric(vertical: 11.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 18.sp),
          label: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.fallback,
    required this.size,
    required this.showStatus,
  });

  final String? imageUrl;
  final String fallback;
  final double size;
  final bool showStatus;

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
                        fontSize: size * 0.34,
                      ),
                    )
                  : null,
            ),
          ),
          if (showStatus)
            Positioned(
              right: -1.w,
              bottom: -1.h,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D772),
                  shape: BoxShape.circle,
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
