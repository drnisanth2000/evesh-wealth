import 'package:evesh_wealth/presentation/widgets/wealth_planner/asset_class_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders displayName and current/ideal/gap pills',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssetClassCard(
            displayName: 'Core Equity',
            currentPct: 42.5,
            idealPct: 35.0,
            currentValue: 425000,
            totalPortfolioValue: 1000000,
            children: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Core Equity'), findsOneWidget);
    expect(find.textContaining('Current 42.5%'), findsOneWidget);
    expect(find.textContaining('Ideal 35.0%'), findsOneWidget);
    // Over-allocated by ₹75k: Current ₹425k vs Ideal 35% × ₹10L = ₹350k.
    expect(find.textContaining('Over'), findsOneWidget);
  });

  test('startCollapsed is true when currentValue is 0 (no holdings)', () {
    const card = AssetClassCard(
      displayName: 'Gold',
      currentPct: 0,
      idealPct: 5,
      currentValue: 0,
      totalPortfolioValue: 1000000,
      children: [],
    );
    expect(card.startCollapsed, isTrue);

    const cardWithValue = AssetClassCard(
      displayName: 'Gold',
      currentPct: 0.5,
      idealPct: 5,
      currentValue: 5000,
      totalPortfolioValue: 1000000,
      children: [],
    );
    expect(cardWithValue.startCollapsed, isFalse);
  });
}
