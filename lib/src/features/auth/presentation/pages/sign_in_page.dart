import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.authenticated) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      SignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _showResetPasswordDialog(AppLocalizations t) {
    _resetEmailController.text = _emailController.text.trim();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3553),
          title: Text(
            t.resetPassword,
            style: TextStyle(color: const Color(0xFFF0F2FF), fontSize: 16.sp),
          ),
          content: TextField(
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: TextStyle(color: const Color(0xFFE6E9F7), fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: t.email,
              hintStyle: TextStyle(
                color: const Color(0xFF8089A5),
                fontSize: 14.sp,
              ),
              filled: true,
              fillColor: const Color(0x2FFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                final email = _resetEmailController.text.trim();
                if (email.isEmpty) return;
                context.read<AuthBloc>().add(
                  PasswordResetRequested(email: email),
                );
                Navigator.of(context).pop();
              },
              child: Text(t.sendReset),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final platform = Theme.of(context).platform;
    final showApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    final authState = context.watch<AuthBloc>().state;
    final isLoading = authState.status == AuthStatus.loading;
    final loginError = authState.status == AuthStatus.failure
        ? authState.message
        : null;

    return AuthGradientScaffold(
      footerText: t.authFooter,
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.message != current.message && current.message != null,
        listener: (context, state) {
          final message = state.message;
          if (message == null) return;
          final resolved = message == 'reset_sent' ? t.resetSent : message;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(resolved)));
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
                                        t.welcome,
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
                                        t.signInSubtitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFA4ACC3),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    AuthTextField(
                                      label: t.email,
                                      hint: t.email,
                                      controller: _emailController,
                                      icon: Icons.person_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                        AutofillHints.username,
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
                                        AutofillHints.password,
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
                                    SizedBox(height: 3.h),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => _showResetPasswordDialog(t),
                                        child: Text(
                                          t.forgotPassword,
                                          style: TextStyle(
                                            color: Color(0xFFA985FF),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    AuthPrimaryButton(
                                      label: t.signIn,
                                      isLoading: isLoading,
                                      onPressed: _onSubmit,
                                    ),
                                    if (loginError != null) ...[
                                      SizedBox(height: 10.h),
                                      Text(
                                        loginError,
                                        style: TextStyle(
                                          color: Color(0xFFFFA8B4),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 16.h),
                                    AuthOrDivider(label: t.or),
                                    SizedBox(height: 10.h),
                                    _AuthSocialRow(
                                      showApple: showApple,
                                      isLoading: isLoading,
                                    ),
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t.noAccountPrompt,
                                          style: TextStyle(
                                            color: Color(0xFF9AA3BC),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.go('/signup'),
                                          child: Text(
                                            t.signUp,
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

class _AuthSocialRow extends StatelessWidget {
  const _AuthSocialRow({required this.showApple, required this.isLoading});

  final bool showApple;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: t.googleSignIn,
            onTap: isLoading
                ? null
                : () => context.read<AuthBloc>().add(
                    const GoogleSignInRequested(),
                  ),
          ),
        ),
        if (showApple) ...[
          SizedBox(width: 10.w),
          Expanded(
            child: _SocialButton(
              icon: Icons.apple_rounded,
              label: t.appleSignIn,
              onTap: isLoading
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AppleSignInRequested(),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDCE2F5),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 7.w),
      ),
      icon: Icon(icon, size: 18.sp),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
      ),
    );
  }
}
