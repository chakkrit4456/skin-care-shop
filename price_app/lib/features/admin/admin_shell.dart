import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';

const _items = [
  ('/admin/products', Icons.inventory_2_outlined, 'nav_products'),
  ('/admin/categories', Icons.category_outlined, 'nav_categories'),
  ('/admin/orders', Icons.receipt_long_outlined, 'nav_orders'),
  ('/admin/users', Icons.people_outline, 'nav_members'),
];

class AdminShell extends ConsumerWidget {
  final String location;
  final Widget child;
  const AdminShell({super.key, required this.location, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (profile.valueOrNull?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t(context, 'admin_only')),
            TextButton(onPressed: () => context.go('/'), child: Text(t(context, 'back_to_shop'))),
          ]),
        ),
      );
    }

    final index = _items.indexWhere((i) => location.startsWith(i.$1)).clamp(0, _items.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('${t(context, 'manage_shop')} · ${t(context, _items[index].$3)}'),
        leading: IconButton(icon: const Icon(Icons.storefront), tooltip: t(context, 'shop_page'), onPressed: () => context.go('/')),
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: index,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => context.go(_items[i].$1),
                destinations: [for (final i in _items) NavigationRailDestination(icon: Icon(i.$2), label: Text(t(context, i.$3)))],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ])
          : child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(_items[i].$1),
              destinations: [for (final i in _items) NavigationDestination(icon: Icon(i.$2), label: t(context, i.$3))],
            ),
    );
  }
}
