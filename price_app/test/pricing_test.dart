import 'package:flutter_test/flutter_test.dart';
import 'package:price_app/core/models.dart';
import 'package:price_app/core/pricing.dart';

void main() {
  final p = Product(id: 1, name: 'ครีมซอง', retailPrice: 29, vipPrice: 25, tiers: [
    PriceTier(minQty: 5, unitPrice: 26),
    PriceTier(minQty: 10, unitPrice: 24),
    PriceTier(minQty: 10, unitPrice: 22, forRole: 'vip'),
  ]);

  test('regular customer gets tier by qty', () {
    expect(unitPrice(p, 1, vip: false), 29);
    expect(unitPrice(p, 4, vip: false), 29);
    expect(unitPrice(p, 5, vip: false), 26);
    expect(unitPrice(p, 9, vip: false), 26);
    expect(unitPrice(p, 10, vip: false), 24);
    expect(unitPrice(p, 100, vip: false), 24);
  });

  test('vip gets vip price and vip tiers', () {
    expect(unitPrice(p, 1, vip: true), 25);
    expect(unitPrice(p, 5, vip: true), 25); // VIP 1-piece price already beats the 5-piece tier
    expect(unitPrice(p, 10, vip: true), 22);
  });

  test('options are one per qty, sorted', () {
    expect(priceOptions(p, vip: false).map((o) => o.minQty), [1, 5, 10]);
    expect(priceOptions(p, vip: true).map((o) => o.price), [25, 26, 22]);
  });

  test('next option hint', () {
    expect(nextOption(p, 3, vip: false)?.minQty, 5);
    expect(nextOption(p, 10, vip: false), isNull);
    expect(nextOption(p, 1, vip: true)?.minQty, 10); // skips 5 because 26 > 25
  });
}
