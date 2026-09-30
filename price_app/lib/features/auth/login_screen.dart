import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await signIn(_user.text, _pass.text);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'login'))),
      body: Constrained(
        maxWidth: 420,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const Entrance(child: _LoginLogo()),
            const SizedBox(height: 16),
            TextFormField(
              controller: _user,
              decoration: InputDecoration(labelText: t(context, 'username')),
              validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'username_required') : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'password')),
              validator: (v) => (v ?? '').isEmpty ? t(context, 'password_required') : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? t(context, 'logging_in') : t(context, 'login'))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pushReplacement(Uri(path: '/register', queryParameters: from == null ? null : {'from': from}).toString()),
              child: Text(t(context, 'no_account')),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/logo.png',
        height: 180,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        isAntiAlias: true,
      );
}
