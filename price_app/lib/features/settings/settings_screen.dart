import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final loggedIn = ref.watch(authStateProvider).loggedIn;
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'settings'))),
      body: Constrained(
        maxWidth: 640,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(t(context, 'language'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'th', label: Text('ไทย')),
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'zh', label: Text('中文')),
            ],
            selected: {prefs.locale.languageCode},
            onSelectionChanged: (v) => ref.read(prefsProvider).setLocale(v.first),
          ),
          const SizedBox(height: 24),
          Text(t(context, 'theme'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(t(context, 'theme_light'))),
              ButtonSegment(value: ThemeMode.dark, label: Text(t(context, 'theme_dark'))),
              ButtonSegment(value: ThemeMode.system, label: Text(t(context, 'theme_system'))),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (v) => ref.read(prefsProvider).setTheme(v.first),
          ),
          const SizedBox(height: 24),
          Text(t(context, 'account'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (loggedIn) const _PasswordCard() else TextButton(onPressed: () => context.push('/login'), child: Text(t(context, 'login_for_password'))),
          const SizedBox(height: 24),
          Text(t(context, 'legal'), style: Theme.of(context).textTheme.titleMedium),
          for (final doc in ['terms', 'privacy', 'purchase', 'licenses', 'about'])
            Card(
              child: ListTile(
                title: Text(t(context, doc)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/$doc'),
              ),
            ),
        ]),
      ),
    );
  }
}

class _PasswordCard extends ConsumerStatefulWidget {
  const _PasswordCard();
  @override
  ConsumerState<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<_PasswordCard> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  bool _busy = false;

  Future<void> _change() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await api.post('/me/password', {'current_password': _current.text, 'new_password': _new.text});
      _current.clear();
      _new.clear();
      _new2.clear();
      if (mounted) showMessage(context, t(context, 'password_changed'));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t(context, 'change_password'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'current_password')),
              validator: (v) => (v ?? '').isEmpty ? t(context, 'current_password_required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _new,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'new_password'), helperText: t(context, 'password_hint')),
              validator: (v) => (v ?? '').length < 8 ? t(context, 'password_short') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _new2,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'confirm_new_password')),
              validator: (v) => v != _new.text ? t(context, 'password_mismatch') : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _busy ? null : _change, child: Text(_busy ? t(context, 'changing') : t(context, 'change_password'))),
          ]),
        ),
      ),
    );
  }
}
