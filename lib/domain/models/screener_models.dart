library;

/// Domain models for MF Screener and Decision Matrix.

// ---------------------------------------------------------------------------
// ScreenerFilters
// ---------------------------------------------------------------------------

/// Immutable filter state for the MF Screener.
class ScreenerFilters {
  final String? category;
  final String? subCategory;
  final String? amc;
  final double? aumMin;
  final double? aumMax;
  final double? erMax;
  final double? return1yMin;
  final double? return3yMin;
  final double? return5yMin;
  final double? return3mMin;
  final double? return6mMin;
  final double? infoRatio3yMin;
  final List<String>? riskometer;
  final String? benchmarkContains;
  final int? ratingMin;
  final String? planType;
  final String sortBy;
  final bool sortAsc;
  final String? searchQuery;
  final String? quickView;

  const ScreenerFilters({
    this.category,
    this.subCategory,
    this.amc,
    this.aumMin,
    this.aumMax,
    this.erMax,
    this.return1yMin,
    this.return3yMin,
    this.return5yMin,
    this.return3mMin,
    this.return6mMin,
    this.infoRatio3yMin,
    this.riskometer,
    this.benchmarkContains,
    this.ratingMin,
    this.planType,
    this.sortBy = 'return_1y',
    this.sortAsc = false,
    this.searchQuery,
    this.quickView,
  });

  /// Returns a copy with only the provided fields replaced.
  /// Use a nullable-function pattern so callers can explicitly set null.
  ScreenerFilters copyWith({
    String? Function()? category,
    String? Function()? subCategory,
    String? Function()? amc,
    double? Function()? aumMin,
    double? Function()? aumMax,
    double? Function()? erMax,
    double? Function()? return1yMin,
    double? Function()? return3yMin,
    double? Function()? return5yMin,
    double? Function()? return3mMin,
    double? Function()? return6mMin,
    double? Function()? infoRatio3yMin,
    List<String>? Function()? riskometer,
    String? Function()? benchmarkContains,
    int? Function()? ratingMin,
    String? Function()? planType,
    String? sortBy,
    bool? sortAsc,
    String? Function()? searchQuery,
    String? Function()? quickView,
  }) {
    return ScreenerFilters(
      category: category != null ? category() : this.category,
      subCategory: subCategory != null ? subCategory() : this.subCategory,
      amc: amc != null ? amc() : this.amc,
      aumMin: aumMin != null ? aumMin() : this.aumMin,
      aumMax: aumMax != null ? aumMax() : this.aumMax,
      erMax: erMax != null ? erMax() : this.erMax,
      return1yMin: return1yMin != null ? return1yMin() : this.return1yMin,
      return3yMin: return3yMin != null ? return3yMin() : this.return3yMin,
      return5yMin: return5yMin != null ? return5yMin() : this.return5yMin,
      return3mMin: return3mMin != null ? return3mMin() : this.return3mMin,
      return6mMin: return6mMin != null ? return6mMin() : this.return6mMin,
      infoRatio3yMin:
          infoRatio3yMin != null ? infoRatio3yMin() : this.infoRatio3yMin,
      riskometer: riskometer != null ? riskometer() : this.riskometer,
      benchmarkContains: benchmarkContains != null
          ? benchmarkContains()
          : this.benchmarkContains,
      ratingMin: ratingMin != null ? ratingMin() : this.ratingMin,
      planType: planType != null ? planType() : this.planType,
      sortBy: sortBy ?? this.sortBy,
      sortAsc: sortAsc ?? this.sortAsc,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
      quickView: quickView != null ? quickView() : this.quickView,
    );
  }

  /// True if any filter beyond defaults is set.
  bool get hasActiveFilters => activeFilterCount > 0;

  /// Count of active (non-default) filters.
  int get activeFilterCount {
    int count = 0;
    if (category != null) count++;
    if (subCategory != null) count++;
    if (amc != null) count++;
    if (aumMin != null) count++;
    if (aumMax != null) count++;
    if (erMax != null) count++;
    if (return1yMin != null) count++;
    if (return3yMin != null) count++;
    if (return5yMin != null) count++;
    if (return3mMin != null) count++;
    if (return6mMin != null) count++;
    if (infoRatio3yMin != null) count++;
    if (riskometer != null && riskometer!.isNotEmpty) count++;
    if (benchmarkContains != null && benchmarkContains!.isNotEmpty) count++;
    if (ratingMin != null) count++;
    if (planType != null) count++;
    if (sortBy != 'return_1y') count++;
    if (sortAsc) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (quickView != null) count++;
    return count;
  }

  /// Pre-built quick-view filter presets.
  ///
  /// IMPORTANT: presets filter on the canonical SEBI `sub_category` column
  /// (not the legacy `category` column which is heterogeneous and mixes
  /// "Equity"/"Debt"/"Hybrid" with "Equity Scheme - Large Cap Fund").
  /// `sub_category` is populated for ~5,447 active funds and contains
  /// 41 distinct SEBI canonical strings.
  static const Map<String, ScreenerFilters> quickViews = {
    // ~116 funds; sort by 3y return so we surface long-term leaders.
    'Large Cap Leaders': ScreenerFilters(
      subCategory: 'Large Cap',
      sortBy: 'return_3y',
    ),
    // ~106 funds.
    'Mid Cap Growth': ScreenerFilters(
      subCategory: 'Mid Cap',
      sortBy: 'return_3y',
    ),
    // ~128 funds; 5y return reflects through-cycle alpha.
    'Small Cap Alpha': ScreenerFilters(
      subCategory: 'Small Cap',
      sortBy: 'return_5y',
    ),
    // ~145 funds.
    'Flexi Cap': ScreenerFilters(
      subCategory: 'Flexi Cap',
      sortBy: 'return_3y',
    ),
    // ~102 funds.
    'Multi Cap': ScreenerFilters(
      subCategory: 'Multi Cap',
      sortBy: 'return_3y',
    ),
    // ~158 funds; ELSS (tax saving).
    'ELSS': ScreenerFilters(
      subCategory: 'ELSS',
      sortBy: 'return_3y',
    ),
    // ~1,344 funds; sort by AUM so we surface the most-traded passive funds.
    // Note: expense_ratio is sparsely populated (~27 funds), so we cannot
    // sort by it — AUM is the next-best proxy for "well-established index".
    'Index & ETF': ScreenerFilters(
      subCategory: 'Index Funds ETFs',
      sortBy: 'aum_cr',
    ),
    // ~74 funds.
    'Short Duration Debt': ScreenerFilters(
      subCategory: 'Short Duration',
      sortBy: 'return_1y',
    ),
    // ~91 funds; the ultra-safe parking option.
    'Liquid': ScreenerFilters(
      subCategory: 'Liquid',
      sortBy: 'return_1y',
    ),
  };

  /// Available sort options: key → display label.
  static const Map<String, String> sortOptions = {
    'return_1y': '1Y Return',
    'return_3y': '3Y Return',
    'return_5y': '5Y Return',
    'return_3m': '3M Return',
    'return_6m': '6M Return',
    'info_ratio_3y': '3Y Info Ratio',
    'info_ratio_5y': '5Y Info Ratio',
    'expense_ratio': 'Expense Ratio',
    'aum_cr': 'AUM',
    'fund_rating': 'Rating',
    'fund_name': 'Name',
  };
}

// ---------------------------------------------------------------------------
// Decision Matrix models
// ---------------------------------------------------------------------------

/// Input parameters for the decision matrix calculator.
class DecisionMatrixInput {
  final double amount;
  final int horizonYears;
  final double taxSlabPct;
  final bool isNewRegime;

  const DecisionMatrixInput({
    required this.amount,
    required this.horizonYears,
    required this.taxSlabPct,
    required this.isNewRegime,
  });
}

/// A single row in the decision matrix, representing one instrument.
class DecisionMatrixRow {
  final String instrument;
  final String category;
  final double grossReturn;
  final double taxImpact;
  final double netReturn;
  final double maturityValue;
  final double totalTaxPaid;
  final String taxTreatment;
  final bool isEditable;
  final String? note;

  const DecisionMatrixRow({
    required this.instrument,
    required this.category,
    required this.grossReturn,
    required this.taxImpact,
    required this.netReturn,
    required this.maturityValue,
    required this.totalTaxPaid,
    required this.taxTreatment,
    this.isEditable = false,
    this.note,
  });
}

/// Full result of the decision matrix computation.
class DecisionMatrixResult {
  final DecisionMatrixInput input;
  final List<DecisionMatrixRow> rows;

  const DecisionMatrixResult({
    required this.input,
    required this.rows,
  });
}
