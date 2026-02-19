import 'dart:typed_data';

import 'package:chat_app/src/features/auth/domain/validators/username_validator.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isUploadingPhoto = false;
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      _showSnack(_photoPickError(Localizations.localeOf(context)));
    }
  }

  void _clearPhoto() {
    setState(() {
      _selectedPhoto = null;
      _selectedPhotoBytes = null;
    });
  }

  Future<String?> _uploadPhotoIfSelected() async {
    if (_selectedPhoto == null) return null;
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
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _onSubmit() async {
    final authState = context.read<AuthBloc>().state;
    if (_isUploadingPhoto) return;
    if (authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.authenticated) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    String? uploadedPhotoUrl;
    if (_selectedPhoto != null) {
      setState(() => _isUploadingPhoto = true);
      try {
        uploadedPhotoUrl = await _uploadPhotoIfSelected();
      } catch (_) {
        if (!mounted) return;
        _showSnack(_photoUploadError(Localizations.localeOf(context)));
        // Fallback: continue sign-up without photo instead of blocking auth.
        uploadedPhotoUrl = null;
      }
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }

    if (!mounted) return;
    context.read<AuthBloc>().add(
      SignUpRequested(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        photoUrl: uploadedPhotoUrl,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateUsername(String? value, AppLocalizations t) {
    final text = value?.trim() ?? '';
    final error = UsernameValidator.validate(text);
    if (error == null) return null;
    switch (error) {
      case UsernameValidationError.empty:
        return t.requiredUsername;
      case UsernameValidationError.tooShort:
        return t.usernameMin5;
      case UsernameValidationError.tooLong:
        return t.usernameMax20;
      case UsernameValidationError.latinOnly:
        return t.usernameLatinOnly;
    }
  }

  String? _validateEmail(String? value, AppLocalizations t) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return t.requiredEmail;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return t.invalidEmail;
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations t) {
    final text = value ?? '';
    if (text.isEmpty) return t.requiredPassword;
    if (text.length < 8) return t.minPassword;
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations t) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return t.requiredConfirmPassword;
    if (confirm != _passwordController.text) return t.passwordMismatch;
    return null;
  }

  String _uploadPhotoLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Rasm yuklash',
      'ru' => 'Загрузить фото',
      'tg' => 'Бор кардани акс',
      _ => 'Upload photo',
    };
  }

  String _changePhotoLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Rasmni almashtirish',
      'ru' => 'Изменить фото',
      'tg' => 'Иваз кардани акс',
      _ => 'Change photo',
    };
  }

  String _removePhotoLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Olib tashlash',
      'ru' => 'Удалить',
      'tg' => 'Нест кардан',
      _ => 'Remove',
    };
  }

  String _photoPickError(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Rasmni tanlashda xatolik',
      'ru' => 'Ошибка при выборе фото',
      'tg' => 'Хато ҳангоми интихоби акс',
      _ => 'Failed to pick image',
    };
  }

  String _photoUploadError(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Rasmni yuklashda xatolik',
      'ru' => 'Ошибка при загрузке фото',
      'tg' => 'Хато ҳангоми боркунии акс',
      _ => 'Failed to upload image',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context);
    final authState = context.watch<AuthBloc>().state;
    final isLoading =
        authState.status == AuthStatus.loading || _isUploadingPhoto;

    return AuthGradientScaffold(
      footerText: t.authFooter,
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.message != current.message &&
            current.status == AuthStatus.failure,
        listener: (context, state) {
          final raw = state.message;
          final message = switch (raw) {
            'password_mismatch' => t.passwordMismatch,
            'required_username' => t.requiredUsername,
            'username_min_5' => t.usernameMin5,
            'username_max_20' => t.usernameMax20,
            'username_latin_only' => t.usernameLatinOnly,
            _ => raw ?? t.error,
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 510.w),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: -48.h,
                            right: -4.w,
                            child: AuthTopDecoration(width: 160.w),
                          ),
                          AuthGlassCard(
                            child: Form(
                              key: _formKey,
                              child: AutofillGroup(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 7.h),
                                    Center(
                                      child: Text(
                                        t.signupTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFF7F8FF),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 30.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Center(
                                      child: Text(
                                        t.signupSubtitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFA4ACC3),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    _PhotoPickerSection(
                                      bytes: _selectedPhotoBytes,
                                      onPick: isLoading ? null : _pickPhoto,
                                      onRemove:
                                          _selectedPhoto == null || isLoading
                                          ? null
                                          : _clearPhoto,
                                      pickLabel: _selectedPhoto == null
                                          ? _uploadPhotoLabel(locale)
                                          : _changePhotoLabel(locale),
                                      removeLabel: _removePhotoLabel(locale),
                                    ),
                                    SizedBox(height: 14.h),
                                    AuthTextField(
                                      label: t.username,
                                      hint: t.username,
                                      controller: _usernameController,
                                      icon: Icons.person_outline_rounded,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      textInputAction: TextInputAction.next,
                                      validator: (value) =>
                                          _validateUsername(value, t),
                                    ),
                                    SizedBox(height: 12.h),
                                    AuthTextField(
                                      label: t.email,
                                      hint: t.email,
                                      controller: _emailController,
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      textInputAction: TextInputAction.next,
                                      validator: (value) =>
                                          _validateEmail(value, t),
                                    ),
                                    SizedBox(height: 12.h),
                                    AuthTextField(
                                      label: t.password,
                                      hint: t.password,
                                      controller: _passwordController,
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      textInputAction: TextInputAction.next,
                                      suffixIcon: IconButton(
                                        iconSize: 18.sp,
                                        constraints: BoxConstraints(
                                          minWidth: 32.w,
                                          minHeight: 32.h,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFFA7AECB),
                                        ),
                                      ),
                                      validator: (value) =>
                                          _validatePassword(value, t),
                                    ),
                                    SizedBox(height: 12.h),
                                    AuthTextField(
                                      label: t.confirmPassword,
                                      hint: t.confirmPassword,
                                      controller: _confirmPasswordController,
                                      icon: Icons.lock_person_outlined,
                                      obscureText: _obscureConfirmPassword,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: isLoading
                                          ? null
                                          : (_) => _onSubmit(),
                                      suffixIcon: IconButton(
                                        iconSize: 18.sp,
                                        constraints: BoxConstraints(
                                          minWidth: 32.w,
                                          minHeight: 32.h,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFFA7AECB),
                                        ),
                                      ),
                                      validator: (value) =>
                                          _validateConfirmPassword(value, t),
                                    ),
                                    SizedBox(height: 12.h),
                                    AuthPrimaryButton(
                                      label: t.signUp,
                                      isLoading: isLoading,
                                      onPressed: _onSubmit,
                                    ),
                                    SizedBox(height: 16.h),
                                    AuthOrDivider(label: t.or),
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t.haveAccountPrompt,
                                          style: TextStyle(
                                            color: Color(0xFF9AA3BC),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.go('/auth'),
                                          child: Text(
                                            t.signIn,
                                            style: TextStyle(
                                              color: Color(0xFFA985FF),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
            );
          },
        ),
      ),
    );
  }
}

class _PhotoPickerSection extends StatelessWidget {
  const _PhotoPickerSection({
    required this.bytes,
    required this.onPick,
    required this.onRemove,
    required this.pickLabel,
    required this.removeLabel,
  });

  final Uint8List? bytes;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  final String pickLabel;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
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
            child: bytes == null
                ? Icon(
                    Icons.person_outline_rounded,
                    color: const Color(0xFFB8C2DE),
                    size: 28.sp,
                  )
                : Image.memory(bytes!, fit: BoxFit.cover),
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
              if (bytes != null)
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
