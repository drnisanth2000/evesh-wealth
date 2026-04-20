import 'amfi_category.g.dart';
import 'asset_classes.dart';

/// Resolves a holding's [AssetClass] using AMFI category ID first (canonical),
/// then asset class label, then free-text category, then defaulting to alternate.
///
/// `fund_master.category` is free-text (e.g. "Liquid Fund", "Money Market") and
/// [AssetClass.fromString] only handles exact matches → everything else
/// silently falls to Alternate/Growth. `amfiCategoryId` is the canonical key.
AssetClass resolveAssetClass({
  String? amfiCategoryId,
  String? assetClassLabel,
  String? category,
}) {
  if (amfiCategoryId != null && amfiCategoryId.isNotEmpty) {
    final amfi = AmfiCategoryX.fromId(amfiCategoryId);
    if (amfi != null) return amfi.defaultAssetClass;
  }
  if (assetClassLabel != null && assetClassLabel.isNotEmpty) {
    final cls = AssetClass.fromString(assetClassLabel);
    if (cls != AssetClass.alternate ||
        assetClassLabel.toLowerCase() == 'alternate') {
      return cls;
    }
  }
  if (category != null && category.isNotEmpty) {
    return AssetClass.fromString(category);
  }
  return AssetClass.alternate;
}
