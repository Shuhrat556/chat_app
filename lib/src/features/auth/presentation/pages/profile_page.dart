import 'dart:typed_data';

import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/core/utils/image_utils.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();

  AppUser? _lastSyncedUser;
  AuthStatus? _lastStatus;
  String? _photoUrl;
  Uint8List? _selectedPhotoBytes;
  XFile? _selectedPhoto;
  bool _isUploadingPhoto = false;
  bool _profileSaveRequested = false;
  bool _deleteRequested = false;
  bool _signOutRequested = false;

  @override
  void initState() {
    super.initState();
    _fillFromUser(context.read<AuthBloc>().state.user);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _fillFromUser(AppUser? user) {
    if (user == null) return;
    _lastSyncedUser = user;
    _usernameController.text = user.username;
    _photoUrl = user.photoUrl;
    _selectedPhoto = null;
    _selectedPhotoBytes = null;
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedPhoto = picked;
        _selectedPhotoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_photoPickError())));
    }
  }

  void _clearPhotoSelection() {
    setState(() {
      _selectedPhoto = null;
      _selectedPhotoBytes = null;
      _photoUrl = null;
    });
  }

  Future<String?> _uploadPhotoIfSelected() async {
    if (_selectedPhoto == null) return _photoUrl;
    final bytes = _selectedPhotoBytes ?? await _selectedPhoto!.readAsBytes();
    final extension = _extensionFromName(_selectedPhoto!.name);
    final fileId = const Uuid().v4();
    final ref = FirebaseStorage.instance.ref(
      'profile_photos/$fileId.$extension',
    );
    final metadata = SettableMetadata(
      contentType: _mimeFromExtension(extension),
    );
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() => _isUploadingPhoto = true);
    String? resolvedPhotoUrl;
    try {
      resolvedPhotoUrl = await _uploadPhotoIfSelected();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_photoUploadError())));
      }
      resolvedPhotoUrl = _photoUrl;
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }

    _profileSaveRequested = true;
    _deleteRequested = false;
    _signOutRequested = false;
    if (!mounted) return;
    context.read<AuthBloc>().add(
      ProfileUpdateRequested(
        username: _usernameController.text.trim(),
        photoUrl: resolvedPhotoUrl,
      ),
    );
  }

  void _goToChangePassword() {
    context.push('/change-password');
  }

  void _signOut() {
    _profileSaveRequested = false;
    _deleteRequested = false;
    _signOutRequested = true;
    context.read<AuthBloc>().add(const SignOutRequested());
  }

  String _photoPickError() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Rasmni tanlashda xatolik',
      'ru' => 'Ошибка при выборе фото',
      'tg' => 'Хато ҳангоми интихоби акс',
      _ => 'Failed to pick image',
    };
  }

  String _photoUploadError() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Rasmni yuklashda xatolik',
      'ru' => 'Ошибка при загрузке фото',
      'tg' => 'Хато ҳангоми боркунии акс',
      _ => 'Failed to upload image',
    };
  }

  String _changePasswordLabel() {
    final locale = Localizations.localeOf(context);
    return switch (locale.languageCode) {
      'uz' => 'Parolni almashtirish',
      'ru' => 'Сменить пароль',
      'tg' => 'Иваз кардани парол',
      _ => 'Change password',
    };
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
                _profileSaveRequested = false;
                _signOutRequested = false;
                _deleteRequested = true;
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

              if (state.status == AuthStatus.unauthenticated) {
                if (_deleteRequested) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.accountDeleted)),
                  );
                } else if (_signOutRequested) {
                  messenger.showSnackBar(SnackBar(content: Text(t.signOut)));
                }
                _profileSaveRequested = false;
                _deleteRequested = false;
                _signOutRequested = false;
                if (mounted) {
                  context.go('/auth');
                }
                return;
              }

              if (state.status == AuthStatus.failure && state.message != null) {
                messenger.showSnackBar(SnackBar(content: Text(state.message!)));
                _profileSaveRequested = false;
                _deleteRequested = false;
                _signOutRequested = false;
              } else if (_profileSaveRequested &&
                  _lastStatus == AuthStatus.loading &&
                  state.status == AuthStatus.authenticated) {
                messenger.showSnackBar(
                  SnackBar(content: Text(t.profileUpdated)),
                );
                _profileSaveRequested = false;
              }
              _lastStatus = state.status;
            },
            builder: (context, state) {
              final user = state.user;
              final isBusy =
                  state.status == AuthStatus.loading || _isUploadingPhoto;

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

              return Stack(
                children: [
                  Column(
                    children: [
                      _ProfileTopBar(
                        user: user,
                        title: t.profileTitle,
                        subtitle: t.profileSubtitle,
                        isBusy: isBusy,
                        onSignOut: _signOut,
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
                                          _ProfilePhotoPicker(
                                            networkPhotoUrl: _photoUrl,
                                            selectedBytes: _selectedPhotoBytes,
                                            onPick: isBusy ? null : _pickPhoto,
                                            onRemove: isBusy
                                                ? null
                                                : _clearPhotoSelection,
                                          ),
                                          SizedBox(height: 8.h),
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
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: isBusy
                                              ? null
                                              : _goToChangePassword,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFDAE4FF,
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.22,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 11.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          icon: Icon(
                                            Icons.lock_reset_rounded,
                                            size: 18.sp,
                                          ),
                                          label: Text(
                                            _changePasswordLabel(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ),
                                      ),
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
    required this.onSignOut,
  });

  final AppUser user;
  final String title;
  final String subtitle;
  final bool isBusy;
  final VoidCallback onSignOut;

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
            onPressed: isBusy ? null : onSignOut,
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
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        color: Colors.white,
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
        filled: true,
        fillColor: const Color(0xFF132444),
        constraints: BoxConstraints(minHeight: 48.h),
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

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.networkPhotoUrl,
    required this.selectedBytes,
    required this.onPick,
    required this.onRemove,
  });

  final String? networkPhotoUrl;
  final Uint8List? selectedBytes;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final networkImage = safeNetworkImage(networkPhotoUrl);
    final hasPhoto = selectedBytes != null || networkImage != null;

    final pickLabel = switch (locale.languageCode) {
      'uz' => hasPhoto ? 'Rasmni yangilash' : 'Rasm qo‘shish',
      'ru' => hasPhoto ? 'Изменить фото' : 'Добавить фото',
      'tg' => hasPhoto ? 'Иваз кардани акс' : 'Иловаи акс',
      _ => hasPhoto ? 'Change photo' : 'Add photo',
    };
    final removeLabel = switch (locale.languageCode) {
      'uz' => 'Rasmni olib tashlash',
      'ru' => 'Удалить фото',
      'tg' => 'Нест кардани акс',
      _ => 'Remove photo',
    };

    return Row(
      children: [
        Container(
          width: 62.w,
          height: 62.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF9D74FF).withValues(alpha: 0.65),
              width: 2.w,
            ),
            color: const Color(0xFF1C2541),
          ),
          child: ClipOval(
            child: selectedBytes != null
                ? Image.memory(selectedBytes!, fit: BoxFit.cover)
                : networkImage != null
                ? Image(image: networkImage, fit: BoxFit.cover)
                : Icon(
                    Icons.person_outline_rounded,
                    color: const Color(0xFFB8C2DE),
                    size: 28.sp,
                  ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: Icon(Icons.file_upload_outlined, size: 16.sp),
                label: Text(
                  pickLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEAF0FF),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                ),
              ),
              if (hasPhoto)
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: Icon(Icons.close_rounded, size: 15.sp),
                  label: Text(
                    removeLabel,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB4BD),
                    side: BorderSide(
                      color: const Color(0xFFFF8A96).withValues(alpha: 0.45),
                    ),
                    backgroundColor: const Color(
                      0xFFFF8A96,
                    ).withValues(alpha: 0.08),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
