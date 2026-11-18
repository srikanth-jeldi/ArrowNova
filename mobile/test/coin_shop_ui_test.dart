import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/theme_shop_screen.dart';

void main() {
  testWidgets('buy shield, buy and place sofa, reopen with one debit each', (
    tester,
  ) async {
    final p = PlayerProgress(completed: {for (var i = 1; i <= 20; i++) i});
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeShopScreen(progress: p, onChanged: () => saves++),
      ),
    );
    await tester.tap(find.text('Buy · 200'));
    await tester.pumpAndSettle();
    expect(p.coins, 600);
    expect(find.text('Owned'), findsWidgets);
    await tester.tap(find.text('Coin décor shop'));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('decor-action-decor_0_4'));
    await tester.scrollUntilVisible(
      action,
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(action), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(p.coins, 200);
    await Scrollable.ensureVisible(tester.element(action), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    final restored = PlayerProgress.fromJson(p.toJson());
    expect(restored.homeDecor.current.placed['Sofas'], 'decor_0_4');
    expect(restored.coins, 200);
    expect(saves, 3);
  });
}
