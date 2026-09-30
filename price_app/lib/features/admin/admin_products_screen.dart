import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          child: TextField(
            decoration: InputDecoration(hintText: t(context, 'search'), prefixIcon: const Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
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
