import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../cart/cart_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'my_orders'))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOrdersProvider.future),
        child: ref.watch(myOrdersProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) => list.isEmpty
                  ? ListView(children: [Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(t(context, 'no_orders_yet'))))])
                  : Constrained(
                      child: ListView(padding: const EdgeInsets.all(12), children: [
                        for (final o in list)
                          OrderCard(
                            order: o,
                            actions: Config.lineOaId.isEmpty
                                ? null
                                : Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => sendOrderToLine(o),
                                      icon: const Icon(Icons.chat),
                                      label: Text(t(context, 'send_line')),
                                    ),
                                  ),
                          ),
                      ]),
                    ),
            ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final bool showCustomer;
  final Widget? actions;
  const OrderCard({super.key, required this.order, this.showCustomer = false, this.actions});

  static const _statusColor = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'shipped': brandGreen,
    'cancelled': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final o = order;
    final c = o.customer;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 8),
            Text(DateFormat('d/M/yy HH:mm').format(o.createdAt), style: const TextStyle(color: muted)),
            const Spacer(),
            Chip(
              label: Text(statusLabel(context, o.status), style: const TextStyle(color: Colors.white)),
              backgroundColor: _statusColor[o.status],
              side: BorderSide.none,
            ),
          ]),
          if (showCustomer && c != null)
            Text('${c.name} (@${c.username})${c.phone == null || c.phone!.isEmpty ? '' : ' · ${c.phone}'}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          if (o.shipBlock.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(t(context, 'ship_to'), style: const TextStyle(fontWeight: FontWeight.w700)),
            SelectableText(o.shipBlock),
          ],
          const Divider(),
          for (final i in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text('${i.productName}  x${i.qty}  @${baht(i.unitPrice)}')),
                Text(baht(i.unitPrice * i.qty)),
              ]),
            ),
          const Divider(),
          Row(children: [
            Text(t(context, 'sum')),
            const Spacer(),
            Text(baht(o.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: brandGreenDark)),
          ]),
          if (o.note != null && o.note!.isNotEmpty) Text(tf(context, 'note_prefix', {'text': o.note!}), style: const TextStyle(color: muted)),
          if (o.trackingNo != null && o.trackingNo!.isNotEmpty)
            SelectableText(tf(context, 'tracking', {'no': o.trackingNo!}), style: const TextStyle(fontWeight: FontWeight.w600)),
          if (actions != null) actions!,
        ]),
      ),
    );
  }
}
