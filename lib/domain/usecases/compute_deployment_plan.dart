import '../../core/constants/asset_classes.dart';
import '../../core/constants/bucket_mapping.dart';
import '../../presentation/providers/bucket_composition_provider.dart';

class DeploymentPlan {
  final List<DeploymentBucket> buckets;
  final double totalLumpsum;
  final double totalSip;
  const DeploymentPlan({
    required this.buckets,
    required this.totalLumpsum,
    required this.totalSip,
  });

  Map<String, dynamic> toJson() => {
        'totalLumpsum': totalLumpsum,
        'totalSip': totalSip,
        'buckets': buckets.map((b) => b.toJson()).toList(),
      };
}

class DeploymentBucket {
  final Bucket bucket;
  final double totalAmount;
  final List<DeploymentLine> lines;
  const DeploymentBucket({
    required this.bucket,
    required this.totalAmount,
    required this.lines,
  });

  Map<String, dynamic> toJson() => {
        'bucket': bucket.name,
        'totalAmount': totalAmount,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

class DeploymentLine {
  final String fundName;
  final int? amfiCode;
  final String assetClassLabel;
  final double lumpsum;
  final double sip;
  final bool isPlaceholder;
  const DeploymentLine({
    required this.fundName,
    required this.amfiCode,
    required this.assetClassLabel,
    required this.lumpsum,
    required this.sip,
    required this.isPlaceholder,
  });

  Map<String, dynamic> toJson() => {
        'fundName': fundName,
        if (amfiCode != null) 'amfiCode': amfiCode,
        'assetClassLabel': assetClassLabel,
        'lumpsum': lumpsum,
        'sip': sip,
        'isPlaceholder': isPlaceholder,
      };
}

DeploymentPlan computeDeploymentPlan({
  required double lumpsum,
  required double sip,
  required double splitPct,
  required BucketCompositionResult composition,
}) {
  final combined = lumpsum + sip * 12.0;
  if (combined <= 0) {
    return const DeploymentPlan(buckets: [], totalLumpsum: 0, totalSip: 0);
  }

  final under = composition.buckets.where((b) => b.gapPct < -0.5).toList();
  final List<BucketComposition> targets;
  final List<double> weights;
  if (under.isNotEmpty) {
    targets = under;
    weights = under.map((b) => -b.gapPct).toList();
  } else {
    targets = composition.buckets.where((b) => b.targetPct > 0).toList();
    weights = targets.map((b) => b.targetPct).toList();
  }
  if (targets.isEmpty) {
    return const DeploymentPlan(buckets: [], totalLumpsum: 0, totalSip: 0);
  }

  final weightSum = weights.fold<double>(0.0, (s, w) => s + w);
  final perBucketAmounts = [
    for (final w in weights) combined * (w / weightSum),
  ];

  final outBuckets = <DeploymentBucket>[];
  for (var i = 0; i < targets.length; i++) {
    final bc = targets[i];
    final bucketAmount = perBucketAmounts[i];

    final byAc = <AssetClass, List<HoldingLine>>{};
    for (final h in bc.funds) {
      final ac = AssetClass.fromString(h.holding.category);
      (byAc[ac] ??= []).add(h);
    }

    final lines = <DeploymentLine>[];
    if (byAc.isEmpty) {
      // Empty bucket: emit an unresolved placeholder. UI chooses the copy and
      // renders an inline FundSearchDropdown so the user resolves it without
      // leaving the flow.
      lines.add(DeploymentLine(
        fundName: '',
        amfiCode: null,
        assetClassLabel: bc.bucket.displayName,
        lumpsum: bucketAmount * (splitPct / 100.0),
        sip: bucketAmount * ((100.0 - splitPct) / 100.0) / 12.0,
        isPlaceholder: true,
      ));
    } else {
      final perAcAmount = bucketAmount / byAc.length;
      byAc.forEach((ac, holdings) {
        holdings.sort((a, b) =>
            b.holding.currentValue.compareTo(a.holding.currentValue));
        final pick = holdings.first.holding;
        lines.add(DeploymentLine(
          fundName: pick.fundName,
          amfiCode: pick.amfiCode,
          assetClassLabel: ac.displayName,
          lumpsum: perAcAmount * (splitPct / 100.0),
          sip: perAcAmount * ((100.0 - splitPct) / 100.0) / 12.0,
          isPlaceholder: false,
        ));
      });
    }

    outBuckets.add(DeploymentBucket(
      bucket: bc.bucket,
      totalAmount: bucketAmount,
      lines: lines,
    ));
  }

  return DeploymentPlan(
    buckets: outBuckets,
    totalLumpsum: lumpsum,
    totalSip: sip,
  );
}
