import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      SignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f1b2c), Color(0xFF1b2b4c), Color(0xFF233b6e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.message != current.message &&
                current.status == AuthStatus.failure,
            listener: (context, state) {
              final message = state.message ?? 'Xatolik';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LiquidGlass.withOwnLayer(
                  shape: const LiquidRoundedRectangle(borderRadius: 24),
                  settings: LiquidGlassSettings(
                    glassColor: Colors.white.withOpacity(0.1),
                    blur: 20,
                    thickness: 24,
                    lightIntensity: 0.6,
                  ),
                  fake: true,
                  child: Container(
                    width: 520,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Form(
                      key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.welcome,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.signInSubtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              prefixIcon: Icon(Icons.mail),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return t.requiredEmail;
                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailRegex.hasMatch(text))
                                return t.invalidEmail;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            decoration: const InputDecoration(
                              hintText: 'Parol',
                              prefixIcon: Icon(Icons.lock),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                            ),
                            validator: (value) {
                              final text = value ?? '';
                              if (text.isEmpty) return t.requiredPassword;
                              if (text.length < 8) return t.minPassword;
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading =
                                  state.status == AuthStatus.loading;
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _onSubmit,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                      child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(t.signIn),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => context.go('/signup'),
                                child: Text(
                                  t.signUp,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
