import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      ChangePasswordRequested(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  String _title(AppLocalizations t, Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Parolni almashtirish',
      'ru' => 'Сменить пароль',
      'tg' => 'Иваз кардани парол',
      _ => t.resetPassword,
    };
  }

  String _subtitle(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Yangi parol o‘rnatish',
      'ru' => 'Установите новый пароль',
      'tg' => 'Пароли нав насб кунед',
      _ => 'Set a new password',
    };
  }

  String _currentPasswordLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Hozirgi parol',
      'ru' => 'Текущий пароль',
      'tg' => 'Пароли ҷорӣ',
      _ => 'Current password',
    };
  }

  String _newPasswordLabel(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Yangi parol',
      'ru' => 'Новый пароль',
      'tg' => 'Пароли нав',
      _ => 'New password',
    };
  }

  String _savedMessage(Locale locale) {
    return switch (locale.languageCode) {
      'uz' => 'Parol muvaffaqiyatli yangilandi',
      'ru' => 'Пароль успешно обновлен',
      'tg' => 'Парол бомуваффақият иваз шуд',
      _ => 'Password changed successfully',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context);

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
                previous.status != current.status ||
                previous.message != current.message,
            listener: (context, state) {
              if (state.status == AuthStatus.failure && state.message != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message!)));
                return;
              }
              if (state.status == AuthStatus.authenticated &&
                  state.message == 'password_changed') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(_savedMessage(locale))));
                context.pop();
              }
            },
            builder: (context, state) {
              final isBusy = state.status == AuthStatus.loading;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: isBusy ? null : () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 23.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title(t, locale),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18.sp,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                _subtitle(locale),
                                style: TextStyle(
                                  color: const Color(0xFF9FAACC),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF102040), Color(0xFF0D1A36)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrent,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: (value) {
                                final text = value ?? '';
                                if (text.isEmpty) return t.requiredPassword;
                                return null;
                              },
                              decoration: _inputDecoration(
                                hint: _currentPasswordLabel(locale),
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent,
                                  ),
                                  icon: Icon(
                                    _obscureCurrent
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFFA7AECB),
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: (value) {
                                final text = value ?? '';
                                if (text.isEmpty) return t.requiredPassword;
                                if (text.length < 8) return t.minPassword;
                                return null;
                              },
                              decoration: _inputDecoration(
                                hint: _newPasswordLabel(locale),
                                icon: Icons.lock_reset_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                                  icon: Icon(
                                    _obscureNew
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFFA7AECB),
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: (value) {
                                final text = value ?? '';
                                if (text.isEmpty) {
                                  return t.requiredConfirmPassword;
                                }
                                if (text != _newPasswordController.text) {
                                  return t.passwordMismatch;
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                hint: t.confirmPassword,
                                icon: Icons.lock_person_outlined,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFFA7AECB),
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: isBusy ? null : _submit,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  backgroundColor: const Color(0xFF8B58FF),
                                ),
                                icon: isBusy
                                    ? SizedBox(
                                        width: 16.w,
                                        height: 16.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.check_rounded, size: 18.sp),
                                label: Text(
                                  t.saveChanges,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF7C8AB0),
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF96A5C8), size: 19.sp),
      suffixIcon: suffixIcon,
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
    );
  }
}
