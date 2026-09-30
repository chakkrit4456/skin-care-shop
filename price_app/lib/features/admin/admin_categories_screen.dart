import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Category? c]) async {
    final name = TextEditingController(text: c?.name);
    final sort = TextEditingController(text: '${c?.sort ?? 0}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(t(context, c == null ? 'add_category' : 'edit_category')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: t(context, 'name'))),
          const SizedBox(height: 12),
          TextField(controller: sort, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t(context, 'sort_order'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t(context, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t(context, 'save_btn'))),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final data = {'name': name.text.trim(), 'sort': int.tryParse(sort.text) ?? 0};
    try {
      if (c == null) {
        await api.post('/admin/categories', data);
      } else {
        await api.put('/admin/categories/${c.id}', data);
      }
      ref.invalidate(categoriesProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category c) async {
    try {
      await api.delete('/admin/categories/${c.id}');
      ref.invalidate(categoriesProvider);
      ref.invalidate(productsProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(context, ref), child: const Icon(Icons.add)),
      body: ref.watch(categoriesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (list) => ListView(children: [
              for (final c in list)
                ListTile(
                  leading: CircleAvatar(child: Text('${c.sort}')),
                  title: Text(c.name),
                  onTap: () => _edit(context, ref, c),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref, c)),
                ),
            ]),
          ),
    );
  }
}
