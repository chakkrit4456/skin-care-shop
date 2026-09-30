import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

Future<bool> editAddress(BuildContext context, WidgetRef ref, [Address? existing]) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _AddressDialog(existing: existing),
  );
  if (saved == true) ref.invalidate(addressesProvider);
  return saved == true;
}

class _AddressDialog extends StatefulWidget {
  final Address? existing;
  const _AddressDialog({this.existing});
  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.existing?.label);
  late final _name = TextEditingController(text: widget.existing?.recipientName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _line = TextEditingController(text: widget.existing?.addressLine);
  late final _sub = TextEditingController(text: widget.existing?.subdistrict);
  late final _dist = TextEditingController(text: widget.existing?.district);
  late final _prov = TextEditingController(text: widget.existing?.province);
  late final _post = TextEditingController(text: widget.existing?.postalCode);
  late bool _default = widget.existing?.isDefault ?? false;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final data = {
      'label': _label.text.trim(),
      'recipient_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'address_line': _line.text.trim(),
      'subdistrict': _sub.text.trim(),
      'district': _dist.text.trim(),
      'province': _prov.text.trim(),
      'postal_code': _post.text.trim(),
      'is_default': _default,
    };
    try {
      final e = widget.existing;
      if (e == null) {
        await api.post('/me/addresses', data);
      } else {
        await api.put('/me/addresses/${e.id}', data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String key, [String? hint]) => InputDecoration(labelText: t(context, key), helperText: hint == null ? null : t(context, hint));
    return AlertDialog(
      title: Text(t(context, widget.existing == null ? 'add_address' : 'edit_address')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _label, decoration: deco('address_label')),
            const SizedBox(height: 10),
            TextFormField(controller: _name, decoration: deco('recipient'), validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'recipient_required') : null),
            const SizedBox(height: 10),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: deco('phone'), validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'phone_required') : null),
            const SizedBox(height: 10),
            TextFormField(controller: _line, maxLines: 2, decoration: deco('address_detail', 'address_detail_hint'), validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'address_required_field') : null),
            const SizedBox(height: 10),
            TextFormField(controller: _sub, decoration: deco('subdistrict')),
            const SizedBox(height: 10),
            TextFormField(controller: _dist, decoration: deco('district')),
            const SizedBox(height: 10),
            TextFormField(controller: _prov, decoration: deco('province'), validator: (v) => (v ?? '').trim().isEmpty ? t(context, 'province_required') : null),
            const SizedBox(height: 10),
            TextFormField(controller: _post, keyboardType: TextInputType.number, decoration: deco('postal')),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: _default, onChanged: (v) => setState(() => _default = v), title: Text(t(context, 'set_default'))),
          ])),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t(context, 'cancel'))),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? t(context, 'saving') : t(context, 'save_btn'))),
      ],
    );
  }
}
