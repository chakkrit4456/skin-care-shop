import 'models.dart';

class PriceOption {
  final int minQty;
  final double price;
  final bool vip;
  PriceOption(this.minQty, this.price, {this.vip = false});
}

/// All price levels visible to the user, one per min qty (lowest price wins), sorted by qty.
/// Must match the SQL function unit_price().
List<PriceOption> priceOptions(Product p, {required bool vip}) {
  final all = <PriceOption>[
    PriceOption(1, p.retailPrice),
    if (vip && p.vipPrice != null) PriceOption(1, p.vipPrice!, vip: true),
    for (final t in p.tiers)
      if (t.forRole == 'all' || vip) PriceOption(t.minQty, t.unitPrice, vip: t.forRole == 'vip'),
  ];
  final byQty = <int, PriceOption>{};
  for (final o in all) {
    final cur = byQty[o.minQty];
    if (cur == null || o.price < cur.price) byQty[o.minQty] = o;
  }
  return byQty.values.toList()..sort((a, b) => a.minQty.compareTo(b.minQty));
}

/// Level applied at [qty]: the cheapest one whose min qty is reached.
PriceOption activeOption(Product p, int qty, {required bool vip}) => priceOptions(p, vip: vip)
    .where((o) => o.minQty <= qty)
    .reduce((a, b) => b.price <= a.price ? b : a);

double unitPrice(Product p, int qty, {required bool vip}) => activeOption(p, qty, vip: vip).price;

/// Next level that would give a lower price, if any.
PriceOption? nextOption(Product p, int qty, {required bool vip}) {
  final current = unitPrice(p, qty, vip: vip);
  for (final o in priceOptions(p, vip: vip)) {
    if (o.minQty > qty && o.price < current) return o;
  }
  return null;
}
