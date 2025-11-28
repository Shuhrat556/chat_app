import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    _photoUrlController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final birthDate = DateTime.tryParse(_birthDateController.text);
    if (birthDate == null) return;
    context.read<AuthBloc>().add(
      SignUpRequested(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: birthDate,
        photoUrl: _photoUrlController.text.trim().isEmpty
            ? null
            : _photoUrlController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDateController.text.isNotEmpty
        ? DateTime.tryParse(_birthDateController.text) ??
              DateTime(now.year - 18, now.month, now.day)
        : DateTime(now.year - 18, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selected != null) {
      final formatted = selected.toIso8601String().split('T').first;
      _birthDateController.text = formatted;
      setState(() {});
    }
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
              final message = state.message ?? t.error;
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
                    width: 560,
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.signupTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.signupSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _usernameController,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                hintText: 'Username',
                                prefixIcon: Icon(Icons.person),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return t.requiredUsername;
                                if (text.length < 3) return t.minUsername;
                                if (text.contains(' ')) return t.noSpaces;
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      hintText: 'Ism',
                                      prefixIcon: Icon(Icons.badge),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty)
                                        return t.requiredFirstName;
                                      if (text.length < 2) return t.minTwoChars;
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      hintText: 'Familiya',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty)
                                        return t.requiredLastName;
                                      if (text.length < 2) return t.minTwoChars;
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _birthDateController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Tug‘ilgan sana (YYYY-MM-DD)',
                                      prefixIcon: Icon(Icons.cake),
                                      suffixIcon: Icon(Icons.calendar_today),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    onTap: _pickBirthDate,
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) return t.requiredBirth;
                                      final parsed = DateTime.tryParse(text);
                                      if (parsed == null) return t.invalidDate;
                                      if (parsed.isAfter(DateTime.now()))
                                        return t.futureDate;
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _photoUrlController,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      hintText: 'Profil rasmi URL (ixtiyoriy)',
                                      prefixIcon: Icon(Icons.image_outlined),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bioController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Bio / About (ixtiyoriy)',
                                prefixIcon: Icon(Icons.info_outline),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
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
                                        : Text(t.signUp),
                                  ),
                                );
                              },
                            ),
                            TextButton(
                              onPressed: () => context.go('/auth'),
                              child: Text(
                                t.backToSignIn,
                                style: const TextStyle(color: Colors.white),
                              ),
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
      ),
    );
  }
}
