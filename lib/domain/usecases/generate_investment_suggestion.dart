import '../../data/models/fund_model.dart';
import '../../data/models/portfolio_summary_model.dart';

class InvestmentSuggestion {
  const InvestmentSuggestion({
    required this.fund,
    required this.assetClass,
    required this.suggestedAmount,
    required this.isSip,
    required this.rationale,
  });

  final FundModel fund;
  final String assetClass;
  final double suggestedAmount;
  final bool isSip;
  final String rationale;
}

class SuggestionResult {
  const SuggestionResult({
    required this.suggestions,
    required this.surplusAmount,
    required this.sipRecommended,
  });

  final List<InvestmentSuggestion> suggestions;
  final double surplusAmount;
  final bool sipRecommended;
}

class InvestmentSuggestionEngine {
  static SuggestionResult generate({
    required double surplusAmount,
    required PortfolioSummary portfolio,
    required Map<String, double> targetAllocation,
    required List<FundModel> availableFunds,
    double? niftyPE,
  }) {
    // Determine SIP vs lumpsum based on Nifty P/E
    // P/E > 25 → prefer SIP, P/E < 20 → lumpsum ok
    final sipRecommended = niftyPE == null || niftyPE > 22;

    // Find underfunded asset classes (current % below target)
    final currentTotal = portfolio.currentValue;
    final gaps = <String, double>{};
    for (final entry in targetAllocation.entries) {
      final targetPct = entry.value;
      final currentPct = portfolio.allocationPct[entry.key] ?? 0.0;
      final gap = targetPct - currentPct;
      if (gap > 0) {
        // proportional allocation of surplus based on gap size
        gaps[entry.key] = gap;
      }
    }

    if (gaps.isEmpty) {
      // Portfolio is well-balanced — suggest top-rated funds in existing allocation
      for (final e in targetAllocation.entries) {
        gaps[e.key] = e.value;
      }
    }

    final totalGap = gaps.values.fold(0.0, (a, b) => a + b);
    if (totalGap <= 0) return SuggestionResult(
      suggestions: [], surplusAmount: surplusAmount, sipRecommended: sipRecommended);

    // Allocate surplus proportionally to gaps
    final allocationPerClass = <String, double>{};
    for (final e in gaps.entries) {
      allocationPerClass[e.key] = surplusAmount * (e.value / totalGap);
    }

    // Score + rank available funds per asset class
    final suggestions = <InvestmentSuggestion>[];

    for (final classEntry in allocationPerClass.entries) {
      final assetClass = classEntry.key;
      final allocation = classEntry.value;
      if (allocation < 500) continue; // too small to split

      // Find matching funds
      final matching = availableFunds.where((f) {
        final taxCat = (f.taxCategory ?? '').toLowerCase();
        final cat = (f.category ?? '').toLowerCase();

        if (assetClass.toLowerCase().contains('equity')) {
          return taxCat == 'equity' || taxCat == 'hybrid-e';
        }
        if (assetClass.toLowerCase().contains('debt')) {
          return taxCat == 'debt' || taxCat == 'hybrid-d';
        }
        if (assetClass.toLowerCase().contains('liquid')) {
          return cat.contains('liquid') || cat.contains('overnight');
        }
        if (assetClass.toLowerCase().contains('gold')) {
          return taxCat == 'gold';
        }
        return false;
      }).toList();

      if (matching.isEmpty) continue;

      // Score: CRISIL rating first, then 3Y return
      matching.sort((a, b) {
        final crisilA = _crisilScore(a.crisilRating);
        final crisilB = _crisilScore(b.crisilRating);
        if (crisilA != crisilB) return crisilB.compareTo(crisilA);
        final r3a = a.return3y ?? -99;
        final r3b = b.return3y ?? -99;
        return r3b.compareTo(r3a);
      });

      // Pick top 3 and split allocation
      final top = matching.take(3).toList();
      final perFund = allocation / top.length;
      for (final fund in top) {
        suggestions.add(InvestmentSuggestion(
          fund: fund,
          assetClass: assetClass,
          suggestedAmount: perFund,
          isSip: sipRecommended,
          rationale: _buildRationale(fund, assetClass, sipRecommended, niftyPE),
        ));
      }
    }

    return SuggestionResult(
      suggestions: suggestions,
      surplusAmount: surplusAmount,
      sipRecommended: sipRecommended,
    );
  }

  static int _crisilScore(String? rating) {
    if (rating == null) return 0;
    if (rating.contains('1')) return 5;
    if (rating.contains('2')) return 4;
    if (rating.contains('3')) return 3;
    if (rating.contains('4')) return 2;
    if (rating.contains('5')) return 1;
    return 0;
  }

  static String _buildRationale(
    FundModel fund, String assetClass, bool isSip, double? pe) {
    final parts = <String>[];
    if (fund.crisilRating != null) {
      parts.add('CRISIL ${fund.crisilRating}');
    }
    if (fund.return3y != null) {
      parts.add('3Y return ${fund.return3y!.toStringAsFixed(1)}%');
    }
    if (isSip && pe != null) {
      parts.add('SIP preferred (Nifty P/E ${pe.toStringAsFixed(0)})');
    }
    return 'Recommended for $assetClass. ${parts.join(' • ')}';
  }
}
