import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_app/core/models.dart';
import 'package:price_app/features/cart/cart_provider.dart';
import 'package:price_app/features/catalog/price_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final product = Product(id: 1, name: 'ครีมซอง', retailPrice: 29, tiers: [
    PriceTier(minQty: 5, unitPrice: 26),
    PriceTier(minQty: 10, unitPrice: 24),
  ]);

  testWidgets('price sheet switches tier with qty and adds to cart', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) => TextButton(onPressed: () => showPriceSheet(c, product), child: const Text('open'))),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('ปลีก 1 ชิ้น'), findsOneWidget);
    expect(find.text('ส่ง 10 ชิ้น'), findsOneWidget);
    expect(find.text('฿29 / ชิ้น'), findsOneWidget);

    await tester.tap(find.text('ส่ง 10 ชิ้น'));
    await tester.pumpAndSettle();
    expect(find.text('฿24 / ชิ้น'), findsOneWidget);
    expect(find.text('฿240'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '7');
    await tester.pumpAndSettle();
    expect(find.text('฿26 / ชิ้น'), findsOneWidget);
    expect(find.text('฿182'), findsOneWidget);

    await tester.ensureVisible(find.text('ใส่ตะกร้า 7 ชิ้น'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ใส่ตะกร้า 7 ชิ้น'));
    await tester.pumpAndSettle();
    expect(container.read(cartProvider), {1: 7});
    expect(find.text('ปลีก 1 ชิ้น'), findsNothing);
  });
}
