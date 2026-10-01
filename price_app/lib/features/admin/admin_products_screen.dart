import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cats = {for (final c in ref.watch(categoriesProvider).valueOrNull ?? []) c.id: c.name};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/products/new'),
        icon: const Icon(Icons.add),
        label: Text(t(context, 'add_product')),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: t(context, 'search'), prefixIcon: const Icon(Icons.search)),
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const _ImportDialog()),
              icon: const Icon(Icons.upload_file),
              label: Text(t(context, 'import_excel')),
            ),
          ]),
        ),
        Expanded(
          child: products.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (all) {
              final list = all.where((p) => p.name.toLowerCase().contains(_q)).toList();
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = list[i];
                  final tiers = p.tiers.map((t) => '${t.minQty}+ ${baht(t.unitPrice)}${t.forRole == 'vip' ? ' VIP' : ''}').join(' · ');
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 52, height: 52, child: ProductImage(p.imageUrl)),
                    ),
                    title: Text(p.name, style: TextStyle(color: p.active ? null : muted)),
                    subtitle: Text('${tf(context, 'retail_dot', {'cat': cats[p.categoryId] ?? '-', 'price': baht(p.retailPrice)})}${tiers.isEmpty ? '' : '\n$tiers'}'),
                    trailing: p.active ? const Icon(Icons.chevron_right) : Chip(label: Text(t(context, 'hidden'))),
                    onTap: () => context.go('/admin/products/${p.id}'),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ImportDialog extends ConsumerStatefulWidget {
  const _ImportDialog();
  @override
  ConsumerState<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<_ImportDialog> {
  bool _update = false;
  bool _busy = false;
  String? _summary;
  List<String> _errors = [];

  Future<void> _pickAndImport() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    setState(() {
      _busy = true;
      _summary = null;
      _errors = [];
    });
    try {
      final r = await api.importProducts(file.bytes!, file.name, update: _update);
      ref.invalidate(productsProvider);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      setState(() {
        _summary = tf(context, 'import_done', {'a': '${r['added']}', 'u': '${r['updated']}', 's': '${r['skipped']}'});
        _errors = [for (final e in (r['errors'] as List? ?? [])) '$e'];
      });
    } catch (e) {
      if (mounted) setState(() => _summary = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t(context, 'import_title')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t(context, 'import_hint'), style: const TextStyle(color: muted)),
            TextButton.icon(
              onPressed: () => launchUrl(api.importTemplateUri()),
              icon: const Icon(Icons.download),
              label: Text(t(context, 'import_template')),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _update,
              onChanged: _busy ? null : (v) => setState(() => _update = v ?? false),
              title: Text(t(context, 'import_update')),
            ),
            if (_busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(t(context, 'importing')),
            ],
            if (_summary != null) Text(_summary!, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t(context, 'import_errors')),
              for (final e in _errors) Text('• $e', style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(t(context, 'close'))),
        FilledButton.icon(
          onPressed: _busy ? null : _pickAndImport,
          icon: const Icon(Icons.upload_file),
          label: Text(t(context, 'import_choose')),
        ),
      ],
    );
  }
}
