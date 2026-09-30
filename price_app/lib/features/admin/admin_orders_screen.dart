import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/live.dart';
import '../../core/models.dart';
import '../../core/widgets.dart';
import '../orders/orders_screen.dart';

final _filterProvider = StateProvider<String?>((ref) => 'pending');

final adminOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final status = ref.watch(_filterProvider);
  refreshOnLive(ref, {'orders'});
  final rows = await api.get('/admin/orders', status == null ? null : {'status': status}) as List;
  return rows.map((r) => Order.fromJson(r)).toList();
});

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _update(BuildContext context, WidgetRef ref, Order o, Map<String, dynamic> data) async {
    try {
      await api.patch('/admin/orders/${o.id}', data);
      ref.invalidate(adminOrdersProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tf(context, 'delete_order', {'id': '${o.id}'})),
        content: Text(t(context, 'delete_order_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t(context, 'cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await api.delete('/admin/orders/${o.id}');
      ref.invalidate(adminOrdersProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _editTracking(BuildContext context, WidgetRef ref, Order o) async {
    final ctrl = TextEditingController(text: o.trackingNo);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tf(context, 'tracking_title', {'id': '${o.id}'})),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t(context, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t(context, 'save_btn'))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _update(context, ref, o, {
        'tracking_no': ctrl.text.trim(),
        if (ctrl.text.trim().isNotEmpty && o.status != 'cancelled') 'status': 'shipped',
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          for (final s in [null, ...orderStatuses])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s == null ? t(context, 'all') : statusLabel(context, s), softWrap: false),
                selected: filter == s,
                onSelected: (_) => ref.read(_filterProvider.notifier).state = s,
              ),
            ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(adminOrdersProvider.future),
          child: ref.watch(adminOrdersProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (list) => list.isEmpty
                    ? ListView(children: [Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(t(context, 'no_orders'))))])
                    : ListView(padding: const EdgeInsets.all(12), children: [
                        for (final o in list)
                          OrderCard(
                            order: o,
                            showCustomer: true,
                            actions: Row(children: [
                              DropdownButton<String>(
                                value: o.status,
                                items: [for (final s in orderStatuses) DropdownMenuItem(value: s, child: Text(statusLabel(context, s)))],
                                onChanged: (v) => _update(context, ref, o, {'status': v}),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _editTracking(context, ref, o),
                                icon: const Icon(Icons.local_shipping_outlined),
                                label: Text(t(context, 'tracking_btn')),
                              ),
                              IconButton(
                                tooltip: t(context, 'delete'),
                                onPressed: () => _delete(context, ref, o),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ]),
                          ),
                      ]),
              ),
        ),
      ),
    ]);
  }
}
