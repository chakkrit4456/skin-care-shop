import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/pricing.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../cart/cart_provider.dart';

Future<void> showPriceSheet(BuildContext context, Product product) => showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, __) => Center(
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: PriceSheet(product)),
        ),
      ),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
        );
      },
    );

class PriceSheet extends ConsumerStatefulWidget {
  final Product product;
  const PriceSheet(this.product, {super.key});
  @override
  ConsumerState<PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends ConsumerState<PriceSheet> {
  int _qty = 1;
  final _qtyCtrl = TextEditingController(text: '1');

  void _setQty(int q, {bool fromField = false}) {
    setState(() => _qty = q < 1 ? 1 : q);
    if (!fromField) _qtyCtrl.text = '$_qty';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final vip = ref.watch(isVipProvider);
    final options = priceOptions(p, vip: vip);
    final active = activeOption(p, _qty, vip: vip);
    final next = nextOption(p, _qty, vip: vip);
    final saved = (p.retailPrice - active.price) * _qty;

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 16, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text(t(context, 'choose_price'), style: const TextStyle(color: Color(0xFF6B7280))),
            ]),
          ),
          IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
      ),
      const Divider(height: 1),
      Flexible(
        child: Container(
          color: const Color(0xFFFAFAFB),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (p.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(height: 220, child: ProductImage(p.imageUrl, fit: BoxFit.contain)),
                ),
              if (p.promotion != null || p.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.promotion != null) PromotionBadge(p.promotion!),
                    if (p.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(p.description!, style: const TextStyle(color: Color(0xFF4B5563))),
                      ),
                  ]),
                ),
              const SizedBox(height: 12),
              for (final o in options) _TierCard(option: o, selected: o.minQty == active.minQty, onTap: () => _setQty(o.minQty)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton.filledTonal(onPressed: () => _setQty(_qty - 1), icon: const Icon(Icons.remove)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _qtyCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    onChanged: (v) => _setQty(int.tryParse(v) ?? 1, fromField: true),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(onPressed: () => _setQty(_qty + 1), icon: const Icon(Icons.add)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t(context, 'price_each')),
                    Flexible(child: Text(tf(context, 'piece_price', {'price': baht(active.price)}), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t(context, 'sum')),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(baht(active.price * _qty), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: brandGreenDark)),
                      ),
                    ),
                  ]),
                ]),
              ),
              if (saved > 0 || next != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    [
                      if (saved > 0) tf(context, 'saved_from_retail', {'price': baht(saved)}),
                      if (next != null) tf(context, 'buy_more', {'n': '${next.minQty - _qty}', 'price': baht(next.price)}),
                    ].join(' • '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(tf(context, 'add_to_cart', {'n': '$_qty'})),
                onPressed: () {
                  ref.read(cartProvider.notifier).add(p.id, _qty);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tf(context, 'added_cart', {'name': p.name, 'n': '$_qty'}))));
                  Navigator.pop(context);
                },
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _TierCard extends StatelessWidget {
  final PriceOption option;
  final bool selected;
  final VoidCallback onTap;
  const _TierCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final q = option.minQty;
    final accent = selected ? brandGreen : ink;
    final title = q == 1
        ? t(context, option.vip ? 'price_vip' : 'retail_one')
        : tf(context, 'wholesale_n', {'n': '$q', 'vip': option.vip ? t(context, 'vip_paren') : ''});
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? brandGreen : const Color(0xFFE5E7EB), width: 2),
          ),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? brandGreenLight : const Color(0xFFF1F3F5),
              ),
              child: Text('$q', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: selected ? brandGreenDark : const Color(0xFF4B5563))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(q == 1 ? t(context, 'for_one') : tf(context, 'for_n_up', {'n': '$q'}), style: TextStyle(color: selected ? brandGreen : muted, fontSize: 13)),
              ]),
            ),
            Text(baht(option.price), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: accent)),
          ]),
        ),
      ),
    );
  }
}
