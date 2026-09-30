import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/pricing.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/address_editor.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _note = TextEditingController();
  int? _addressId;
  bool _busy = false;

  Future<void> _checkout(List<(Product, int)> lines, int? addressId) async {
    if (!api.loggedIn) {
      context.push('/login');
      return;
    }
    if (addressId == null) {
      final added = await editAddress(context, ref);
      if (!added || !mounted) return;
      final list = await ref.refresh(addressesProvider.future);
      if (list.isEmpty) return;
      addressId = (list.where((a) => a.isDefault).firstOrNull ?? list.first).id;
    }
    setState(() => _busy = true);
    try {
      final order = Order.fromJson(await api.post('/orders', {
        'items': [for (final (p, q) in lines) {'product_id': p.id, 'qty': q}],
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'address_id': addressId,
      }));
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      _note.clear();
      if (mounted) await _showSuccess(order);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSuccess(Order order) => showDialog(
        context: context,
        builder: (d) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: brandGreen, size: 56),
          title: Text(tf(context, 'order_ok', {'id': '${order.id}'})),
          content: Text(tf(context, 'order_ok_body', {'total': baht(order.total)})),
          actions: [
            if (Config.lineOaId.isNotEmpty)
              OutlinedButton.icon(onPressed: () => sendOrderToLine(order), icon: const Icon(Icons.chat), label: Text(t(context, 'send_line'))),
            FilledButton(
              onPressed: () {
                Navigator.pop(d);
                context.go('/orders');
              },
              child: Text(t(context, 'view_orders')),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final vip = ref.watch(isVipProvider);
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'cart_title'))),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final byId = {for (final p in all) p.id: p};
          final lines = [for (final e in cart.entries) if (byId[e.key]?.active == true) (byId[e.key]!, e.value)];
          if (lines.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_cart_outlined, size: 64, color: muted),
                Text(t(context, 'cart_empty'), style: const TextStyle(color: muted)),
                TextButton(onPressed: () => context.go('/'), child: Text(t(context, 'shop_more'))),
              ]),
            );
          }
          final total = lines.fold<double>(0, (s, l) => s + unitPrice(l.$1, l.$2, vip: vip) * l.$2);
          final addresses = api.loggedIn ? ref.watch(addressesProvider).valueOrNull ?? [] : <Address>[];
          final selected = addresses.any((a) => a.id == _addressId)
              ? _addressId
              : (addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull)?.id;

          return Constrained(
            child: Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.all(12), children: [
                  for (final (p, q) in lines) _CartLine(product: p, qty: q, vip: vip),
                  const SizedBox(height: 8),
                  Text(t(context, 'choose_address'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (!api.loggedIn)
                    Text(t(context, 'login_to_order'), style: const TextStyle(color: muted))
                  else if (addresses.isEmpty)
                    OutlinedButton.icon(onPressed: () => editAddress(context, ref), icon: const Icon(Icons.add_location_alt_outlined), label: Text(t(context, 'add_address')))
                  else
                    for (final a in addresses)
                      Card(
                        child: RadioListTile<int>(
                          value: a.id,
                          groupValue: selected,
                          onChanged: (v) => setState(() => _addressId = v),
                          title: Text(a.label.isEmpty ? a.recipientName : '${a.label} · ${a.recipientName}'),
                          subtitle: Text(a.block),
                          secondary: a.isDefault ? Chip(label: Text(t(context, 'default_address'))) : null,
                        ),
                      ),
                  if (api.loggedIn && addresses.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(onPressed: () => editAddress(context, ref), icon: const Icon(Icons.add), label: Text(t(context, 'add_address'))),
                    ),
                  TextField(controller: _note, maxLines: 2, decoration: InputDecoration(labelText: t(context, 'note'))),
                ]),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(t(context, 'total'), style: const TextStyle(color: muted)),
                      Text(baht(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: brandGreenDark)),
                    ]),
                    const Spacer(),
                    FilledButton(
                      onPressed: _busy ? null : () => _checkout(lines, selected),
                      child: Text(_busy ? t(context, 'ordering') : !api.loggedIn ? t(context, 'login_to_order') : t(context, 'checkout')),
                    ),
                  ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  final Product product;
  final int qty;
  final bool vip;
  const _CartLine({required this.product, required this.qty, required this.vip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final price = unitPrice(product, qty, vip: vip);
    final next = nextOption(product, qty, vip: vip);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 64, height: 64, child: ProductImage(product.imageUrl))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${tf(context, 'piece_price', {'price': baht(price)})}${price < product.retailPrice ? tf(context, 'was_retail', {'price': baht(product.retailPrice)}) : ''}',
                  style: const TextStyle(fontSize: 13, color: brandGreenDark)),
              if (next != null)
                Text(tf(context, 'more_for_price', {'n': '${next.minQty - qty}', 'price': baht(next.price)}), style: const TextStyle(fontSize: 12, color: Colors.red)),
              Text(baht(price * qty), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          Column(children: [
            Row(children: [
              IconButton(onPressed: () => cart.setQty(product.id, qty - 1), icon: const Icon(Icons.remove_circle_outline)),
              Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(onPressed: () => cart.setQty(product.id, qty + 1), icon: const Icon(Icons.add_circle_outline)),
            ]),
            if (next != null)
              TextButton(onPressed: () => cart.setQty(product.id, next.minQty), child: Text(tf(context, 'change_to', {'n': '${next.minQty}'}))),
          ]),
        ]),
      ),
    );
  }
}

/// Opens a chat with the shop's LINE OA with the order summary pre-filled.
Future<void> sendOrderToLine(Order order) async {
  final text = [
    'Order #${order.id}',
    for (final i in order.items) '• ${i.productName} x${i.qty} = ${baht(i.unitPrice * i.qty)}',
    'Total ${baht(order.total)}',
    if (order.shipBlock.isNotEmpty) order.shipBlock,
    if (order.note != null) order.note!,
  ].join('\n');
  final uri = Uri.parse('https://line.me/R/oaMessage/${Uri.encodeComponent(Config.lineOaId)}/?${Uri.encodeComponent(text)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
