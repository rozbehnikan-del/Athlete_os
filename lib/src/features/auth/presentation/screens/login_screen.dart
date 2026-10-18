import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_layout.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});
  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
    if (mounted) _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AuthLayout(
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: auth.isLoading
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 24),
              const AuthHeading(title: 'Sign in to your account'),
              const SizedBox(height: 36),
              TextFormField(
                controller: _email,
                enabled: !auth.isLoading,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your email.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !auth.isLoading,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: auth.isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password.'
                    : null,
                onFieldSubmitted: (_) {
                  if (!auth.isLoading) _submit();
                },
              ),
              if (auth.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      auth.error is RepositoryException &&
                              (auth.error as RepositoryException).message ==
                                  'Email or password is incorrect.'
                          ? 'Email or password is incorrect.'
                          : 'Unable to sign in. Please try again.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                          semanticsLabel: 'Signing in',
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthStatusScreen extends ConsumerWidget {
  const AuthStatusScreen({super.key, this.unsupported = false});
  final bool unsupported;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (auth.isLoading)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    unsupported
                        ? user?.isActive == false
                              ? 'This account is inactive.'
                              : '${user?.role.name ?? 'This role'} experience is not available yet.'
                        : 'Unable to validate your session. Please try again.',
                  ),
                  const SizedBox(height: 16),
                  if (!unsupported)
                    TextButton(
                      onPressed: () => ref.invalidate(authControllerProvider),
                      child: const Text('Retry'),
                    ),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
