import 'package:flutter/material.dart';
import 'asset_classes.dart';
import '../theme/app_colors.dart';

/// 3-bucket classification used by Wealth Planner v2.
///
/// Every holding rolls up into exactly one of:
///   - [liquid]      — emergency cash, ≤6m horizon
///   - [fixedIncome] — capital-preservation, predictable yield
///   - [growth]      — long-horizon, equity-like risk
enum Bucket { liquid, fixedIncome, growth }

extension BucketMeta on Bucket {
  String get displayName {
    switch (this) {
      case Bucket.liquid: return 'Liquid';
      case Bucket.fixedIncome: return 'Fixed Income';
      case Bucket.growth: return 'Growth';
    }
  }

  String get shortLabel {
    switch (this) {
      case Bucket.liquid: return 'LIQ';
      case Bucket.fixedIncome: return 'FI';
      case Bucket.growth: return 'GROW';
    }
  }

  IconData get icon {
    switch (this) {
      case Bucket.liquid: return Icons.water_drop_outlined;
      case Bucket.fixedIncome: return Icons.account_balance_outlined;
      case Bucket.growth: return Icons.trending_up;
    }
  }

  /// Brand-accent color per bucket. Mode-independent (brand) so we read from
  /// [AppColors] rather than the brightness-aware [AppPalette].
  Color get color {
    switch (this) {
      case Bucket.liquid: return AppColors.bucket1;
      case Bucket.fixedIncome: return AppColors.bucket2;
      case Bucket.growth: return AppColors.bucket3;
    }
  }
}

/// Maps an MF holding's [AssetClass] (+ optional [TaxCategory] for hybrids)
/// to its 3-bucket classification.
Bucket bucketFor(AssetClass cls, [TaxCategory? tax]) {
  switch (cls) {
    case AssetClass.liquid:
      return Bucket.liquid;
    case AssetClass.debt:
      return Bucket.fixedIncome;
    case AssetClass.hybrid:
      if (tax == TaxCategory.hybridE) return Bucket.growth;
      // Unknown hybrid sub-type → conservative FI bucket; over-stating equity exposure is the worse error.
      return Bucket.fixedIncome;
    case AssetClass.coreEquity:
    case AssetClass.satelliteEquity:
    case AssetClass.gold:
    case AssetClass.alternate:
      return Bucket.growth;
  }
}

/// Maps a non-MF holding ([AssetType]) to its bucket.
///
/// MF holdings must be classified by their [AssetClass] (since one [AssetType.mf]
/// can be liquid/debt/equity/hybrid), so passing [AssetType.mf] throws.
Bucket bucketForAssetType(AssetType type, {String? subType}) {
  switch (type) {
    case AssetType.fd:
    case AssetType.ppf:
      return Bucket.fixedIncome;
    case AssetType.nps:
      // NPS Tier-1 has equity exposure → growth by default. Only Tier-2 debt
      // ('TierIIDebt' or any subType containing 'debt') maps to FI.
      if (subType?.toLowerCase().contains('debt') == true) return Bucket.fixedIncome;
      return Bucket.growth;
    case AssetType.sgb:
    case AssetType.gold:
    case AssetType.realEstate:
    case AssetType.reit:
    case AssetType.invIt:
    case AssetType.aif:
    case AssetType.sif:
    case AssetType.pms:
    case AssetType.stock:
    case AssetType.other:
      return Bucket.growth;
    case AssetType.mf:
      throw ArgumentError.value(type, 'type', 'Use bucketFor(AssetClass) for MF holdings');
  }
}

/// Resolves the user's manual `bucket_override` DB string to the enum.
/// Returns null on null/unknown so callers can fall back to the auto mapping.
Bucket? bucketFromOverride(String? override) =>
    override == null ? null : Bucket.values.asNameMap()[override];
