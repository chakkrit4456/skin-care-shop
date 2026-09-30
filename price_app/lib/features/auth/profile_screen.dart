import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'address_editor.dart';
import 'auth_service.dart';

String _roleLabel(BuildContext context, String role) => switch (role) {
      'vip' => t(context, 'role_vip_member'),
      'admin' => t(context, 'role_admin'),
      _ => t(context, 'role_customer'),
    };

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'my_profile'))),
      body: ref.watch(profileProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (p) => p == null
                ? Center(child: Text(t(context, 'please_login')))
                // keyed so the form reloads when the profile changes on another device
                : _ProfileForm(key: ValueKey('${p.id}:${p.name}:${p.username}:${p.phone}'), profile: p),
          ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final Profile profile;
  const _ProfileForm({super.key, required this.profile});
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _user = TextEditingController(text: widget.profile.username);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  bool _saving = false;
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
      await api.uploadFile('/me/avatar', await file.readAsBytes(), 'avatar.$ext');
      ref.invalidate(profileProvider);
      if (mounted) showMessage(context, t(context, 'avatar_changed'));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeAvatar() async {
    try {
      await api.delete('/me/avatar');
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await api.patch('/me', {'name': _name.text.trim(), 'username': _user.text.trim(), 'phone': _phone.text.trim()});
      ref.invalidate(profileProvider);
      if (mounted) showMessage(context, t(context, 'saved'));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAddress(Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(t(context, 'delete_address')),
        content: Text(a.block),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t(context, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t(context, 'delete'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete('/me/addresses/${a.id}');
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider).valueOrNull ?? widget.profile;
    return Constrained(
      maxWidth: 480,
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Center(
          child: Stack(children: [
            InkWell(
              onTap: _uploading ? null : _pickAvatar,
              customBorder: const CircleBorder(),
              child: UserAvatar(url: p.avatarUrl, username: p.username, radius: 56),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(
                onPressed: _uploading ? null : _pickAvatar,
                tooltip: t(context, 'change_avatar'),
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.photo_camera, size: 18),
              ),
            ),
          ]),
        ),
        if (p.avatarUrl != null)
          Center(child: TextButton(onPressed: _removeAvatar, child: Text(t(context, 'remove_avatar')))),
        const SizedBox(height: 8),
        Center(child: Chip(label: Text(_roleLabel(context, p.role)))),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t(context, 'personal_info'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: t(context, 'full_name')),
              validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'name_required') : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _user,
              decoration: InputDecoration(labelText: t(context, 'username')),
              validator: (v) => usernamePattern.hasMatch((v ?? '').trim()) ? null : t(context, 'username_rule'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t(context, 'phone')),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? t(context, 'saving') : t(context, 'save'))),
          ]),
        ),
        const Divider(height: 48),
        Row(children: [
          Text(t(context, 'addresses'), style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          TextButton.icon(onPressed: () => editAddress(context, ref), icon: const Icon(Icons.add), label: Text(t(context, 'add_address'))),
        ]),
        const SizedBox(height: 8),
        ...ref.watch(addressesProvider).when(
              loading: () => [const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))],
              error: (e, _) => [Text('$e')],
              data: (list) => list.isEmpty
                  ? [Text(t(context, 'no_address'), style: const TextStyle(color: Colors.black54))]
                  : [
                      for (final a in list)
                        Card(
                          child: ListTile(
                            title: Text(a.label.isEmpty ? a.recipientName : '${a.label} · ${a.recipientName}'),
                            subtitle: Text(a.block),
                            isThreeLine: true,
                            leading: a.isDefault ? Chip(label: Text(t(context, 'default_address'))) : null,
                            onTap: () => editAddress(context, ref, a),
                            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteAddress(a)),
                          ),
                        ),
                    ],
            ),
      ]),
    );
  }
}
