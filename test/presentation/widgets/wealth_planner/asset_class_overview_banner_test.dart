import 'package:evesh_wealth/core/constants/asset_classes.dart';
import 'package:evesh_wealth/presentation/widgets/wealth_planner/asset_class_overview_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      );

  testWidgets('tapping a chip fires onTapClass with the right AssetClass',
      (tester) async {
    AssetClass? tapped;
    await tester.pumpWidget(_wrap(
      AssetClassOverviewBanner(
        entries: const [
          AssetClassOverview(
            assetClass: AssetClass.coreEquity,
            currentPct: 30,
            targetPct: 42,
          ),
          AssetClassOverview(
            assetClass: AssetClass.liquid,
            currentPct: 10,
            targetPct: 6,
          ),
        ],
        onTapClass: (c) => tapped = c,
      ),
    ));

    expect(find.text('Core Equity'), findsOneWidget);
    expect(find.text('Liquid'), findsOneWidget);

    await tester.tap(find.text('Liquid'));
    await tester.pumpAndSettle();
    expect(tapped, AssetClass.liquid);
  });

  testWidgets('balanced chip has no direction icon', (tester) async {
    await tester.pumpWidget(_wrap(
      AssetClassOverviewBanner(
        entries: const [
          AssetClassOverview(
            assetClass: AssetClass.hybrid,
            currentPct: 10.1,
            targetPct: 10.2,
          ),
        ],
        onTapClass: (_) {},
      ),
    ));

    // Neither arrow_downward nor arrow_upward should render for a balanced
    // chip (|Δ| < 0.5pp).
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
  });

  testWidgets('deficit chip shows arrow_downward, excess chip shows arrow_upward',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AssetClassOverviewBanner(
        entries: const [
          AssetClassOverview(
            assetClass: AssetClass.coreEquity,
            currentPct: 20,
            targetPct: 40, // deficit 20pp
          ),
          AssetClassOverview(
            assetClass: AssetClass.liquid,
            currentPct: 15,
            targetPct: 6, // excess 9pp
          ),
        ],
        onTapClass: (_) {},
      ),
    ));

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });
}
