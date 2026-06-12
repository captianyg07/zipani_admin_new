import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_button.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: DS.danger)),
      );
    });

    return Scaffold(
      backgroundColor: DS.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DS.s24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(DS.s32),
            decoration: BoxDecoration(
              color: DS.surface,
              borderRadius: BorderRadius.circular(DS.rXl),
              boxShadow: DS.shadowMd,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: DS.brand,
                            borderRadius: BorderRadius.circular(DS.rMd)),
                        child: const Icon(Icons.restaurant_menu,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: DS.s12),
                      const Text('Zipani',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: DS.ink,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: DS.s32),
                  Text('Sign in', style: AppType.display),
                  const SizedBox(height: DS.s6),
                  Text('Manage restaurants, menus, orders, and offers.',
                      style: AppType.body),
                  const SizedBox(height: DS.s24),
                  Text('Email',
                      style: AppType.small.copyWith(
                          color: DS.inkSoft, fontWeight: FontWeight.w600)),
                  const SizedBox(height: DS.s6),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Enter your email';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: DS.s16),
                  Text('Password',
                      style: AppType.small.copyWith(
                          color: DS.inkSoft, fontWeight: FontWeight.w600)),
                  const SizedBox(height: DS.s6),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: DS.muted),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: DS.s24),
                  AppButton(
                    label: isLoading ? 'Signing in…' : 'Sign in',
                    expand: true,
                    height: 50,
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
