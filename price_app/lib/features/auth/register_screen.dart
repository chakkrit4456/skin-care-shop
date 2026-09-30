import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await signUp(name: _name.text, username: _user.text, password: _pass.text, phone: _phone.text);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'register_title'))),
      body: Constrained(
        maxWidth: 420,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Entrance(child: Text(t(context, 'register_hint'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62)))),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: t(context, 'full_name'), helperText: t(context, 'full_name_hint')),
              validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'name_required') : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _user,
              decoration: InputDecoration(labelText: t(context, 'username'), helperText: t(context, 'username_hint')),
              validator: (v) => usernamePattern.hasMatch((v ?? '').trim()) ? null : t(context, 'username_rule'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t(context, 'phone_optional')),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'password'), helperText: t(context, 'password_hint')),
              validator: (v) => (v ?? '').length < 8 ? t(context, 'password_short') : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass2,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'password_again')),
              validator: (v) => v != _pass.text ? t(context, 'password_mismatch') : null,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? t(context, 'registering') : t(context, 'register'))),
            TextButton(onPressed: () => context.pushReplacement('/login'), child: Text(t(context, 'have_account'))),
          ]),
        ),
      ),
    );
  }
}
