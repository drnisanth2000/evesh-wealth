import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/screener_models.dart';

/// Filter and search bar for the MF Screener.
///
/// Exposes:
///  1. Search row (debounced 300 ms)
///  2. Quick-view chip row
///  3. Sort row (field + direction)
///  4. Active-filter clear button
///  5. Filter button → bottom sheet with detailed filters
class FilterBar extends StatefulWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.categories,
    required this.amcs,
  });

  final ScreenerFilters filters;
  final ValueChanged<ScreenerFilters> onChanged;
  final List<String> categories;
  final List<String> amcs;

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final TextEditingController _searchCtrl;
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  // Tracks the last value we (this widget) pushed up to the parent. Used to
  // distinguish a true external reset from a parent rebuild caused by our own
  // debounced onChanged — without this, didUpdateWidget would clobber the
  // user's in-progress text and trash the cursor on every keystroke.
  String _lastSentQuery = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.filters.searchQuery ?? '';
    _searchCtrl = TextEditingController(text: initial);
    _lastSentQuery = initial;
  }

  @override
  void didUpdateWidget(FilterBar old) {
    super.didUpdateWidget(old);
    final newQuery = widget.filters.searchQuery ?? '';
    // Only sync the controller when the parent's value diverges from what we
    // last reported AND the user isn't actively typing in the field. This is
    // the "external reset" path (e.g. Clear-All button), not the echo from
    // our own debounced update.
    if (newQuery != _lastSentQuery && !_searchFocus.hasFocus) {
      _searchCtrl.text = newQuery;
      _lastSentQuery = newQuery;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _lastSentQuery = value;
      widget.onChanged(
        widget.filters.copyWith(searchQuery: () => value.isEmpty ? null : value),
      );
    });
  }

  void _applyQuickView(String key) {
    final preset = ScreenerFilters.quickViews[key];
    if (preset == null) return;
    // Apply preset but preserve search query
    widget.onChanged(
      ScreenerFilters(
        category: preset.category,
        subCategory: preset.subCategory,
        amc: preset.amc,
        aumMin: preset.aumMin,
        aumMax: preset.aumMax,
        erMax: preset.erMax,
        return1yMin: preset.return1yMin,
        return3yMin: preset.return3yMin,
        return5yMin: preset.return5yMin,
        return3mMin: preset.return3mMin,
        return6mMin: preset.return6mMin,
        infoRatio3yMin: preset.infoRatio3yMin,
        riskometer: preset.riskometer,
        benchmarkContains: preset.benchmarkContains,
        ratingMin: preset.ratingMin,
        planType: preset.planType,
        sortBy: preset.sortBy,
        sortAsc: preset.sortAsc,
        searchQuery: widget.filters.searchQuery,
        quickView: key,
      ),
    );
  }

  void _clearQuickView(String key) {
    // If already selected, deselect
    widget.onChanged(
      const ScreenerFilters().copyWith(
        searchQuery: () => widget.filters.searchQuery,
        quickView: () => null,
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        filters: widget.filters,
        categories: widget.categories,
        amcs: widget.amcs,
        onApply: (f) {
          Navigator.of(ctx).pop();
          widget.onChanged(f);
        },
        onReset: () {
          Navigator.of(ctx).pop();
          widget.onChanged(
            ScreenerFilters(searchQuery: widget.filters.searchQuery),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search funds…',
                  hintStyle: TextStyle(color: context.palette.textTertiary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.palette.textTertiary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: context.palette.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Filter icon button
            _IconToggle(
              icon: Icons.filter_list,
              tooltip: 'Filters',
              active: filters.hasActiveFilters,
              onTap: () => _openFilterSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Quick views row ─────────────────────────────────────────────────
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ScreenerFilters.quickViews.keys.map((key) {
              final selected = filters.quickView == key;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    key,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? AppColors.textOnPrimary
                          : context.palette.textSecondary,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) =>
                      selected ? _clearQuickView(key) : _applyQuickView(key),
                  selectedColor: AppColors.primary,
                  backgroundColor: context.palette.bgSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // ── Sort row ────────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Sort:',
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: ScreenerFilters.sortOptions.containsKey(filters.sortBy)
                    ? filters.sortBy
                    : 'return_1y',
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: context.palette.bgCardElevated,
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textPrimary,
                ),
                icon: Icon(
                  Icons.expand_more,
                  size: 18,
                  color: context.palette.textTertiary,
                ),
                items: ScreenerFilters.sortOptions.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    widget.onChanged(filters.copyWith(sortBy: val));
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(
                filters.sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: context.palette.textSecondary,
              ),
              tooltip: filters.sortAsc ? 'Ascending' : 'Descending',
              onPressed: () {
                widget.onChanged(filters.copyWith(sortAsc: !filters.sortAsc));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            // Clear filters button
            if (filters.hasActiveFilters)
              TextButton.icon(
                icon: const Icon(Icons.close, size: 14),
                label: Text('Clear (${filters.activeFilterCount})'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  textStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  widget.onChanged(const ScreenerFilters());
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ── Small helper: icon with optional active indicator ─────────────────────────

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: Icon(icon, color: context.palette.textSecondary, size: 22),
          tooltip: tooltip,
          onPressed: onTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        if (active)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.filters,
    required this.categories,
    required this.amcs,
    required this.onApply,
    required this.onReset,
  });

  final ScreenerFilters filters;
  final List<String> categories;
  final List<String> amcs;
  final ValueChanged<ScreenerFilters> onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _category;
  late String? _amc;
  late String? _planType; // null=All, 'Direct', 'Regular'
  late double _ratingMin;
  late Set<String> _riskometer;
  final _erMaxCtrl = TextEditingController();
  final _return1yCtrl = TextEditingController();
  final _return3yCtrl = TextEditingController();
  final _return5yCtrl = TextEditingController();
  final _return3mCtrl = TextEditingController();
  final _return6mCtrl = TextEditingController();
  final _infoRatio3yCtrl = TextEditingController();
  final _benchmarkCtrl = TextEditingController();
  final _aumMinCtrl = TextEditingController();
  final _aumMaxCtrl = TextEditingController();

  static const _riskLevels = <String>[
    'Low',
    'Low to Moderate',
    'Moderate',
    'Moderately High',
    'High',
    'Very High',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.filters;
    _category = f.category;
    _amc = f.amc;
    _planType = f.planType;
    _ratingMin = (f.ratingMin ?? 1).toDouble();
    _riskometer = {...?f.riskometer};
    _erMaxCtrl.text = f.erMax?.toString() ?? '';
    _return1yCtrl.text = f.return1yMin?.toString() ?? '';
    _return3yCtrl.text = f.return3yMin?.toString() ?? '';
    _return5yCtrl.text = f.return5yMin?.toString() ?? '';
    _return3mCtrl.text = f.return3mMin?.toString() ?? '';
    _return6mCtrl.text = f.return6mMin?.toString() ?? '';
    _infoRatio3yCtrl.text = f.infoRatio3yMin?.toString() ?? '';
    _benchmarkCtrl.text = f.benchmarkContains ?? '';
    _aumMinCtrl.text = f.aumMin?.toString() ?? '';
    _aumMaxCtrl.text = f.aumMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _erMaxCtrl.dispose();
    _return1yCtrl.dispose();
    _return3yCtrl.dispose();
    _return5yCtrl.dispose();
    _return3mCtrl.dispose();
    _return6mCtrl.dispose();
    _infoRatio3yCtrl.dispose();
    _benchmarkCtrl.dispose();
    _aumMinCtrl.dispose();
    _aumMaxCtrl.dispose();
    super.dispose();
  }

  ScreenerFilters _buildFilters() {
    return widget.filters.copyWith(
      category: () => _category,
      amc: () => _amc,
      planType: () => _planType,
      ratingMin: () => _ratingMin > 1 ? _ratingMin.round() : null,
      erMax: () => double.tryParse(_erMaxCtrl.text),
      return1yMin: () => double.tryParse(_return1yCtrl.text),
      return3yMin: () => double.tryParse(_return3yCtrl.text),
      return5yMin: () => double.tryParse(_return5yCtrl.text),
      return3mMin: () => double.tryParse(_return3mCtrl.text),
      return6mMin: () => double.tryParse(_return6mCtrl.text),
      infoRatio3yMin: () => double.tryParse(_infoRatio3yCtrl.text),
      riskometer: () => _riskometer.isEmpty ? null : _riskometer.toList(),
      benchmarkContains: () =>
          _benchmarkCtrl.text.trim().isEmpty ? null : _benchmarkCtrl.text.trim(),
      aumMin: () => double.tryParse(_aumMinCtrl.text),
      aumMax: () => double.tryParse(_aumMaxCtrl.text),
      quickView: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.bgDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onReset,
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: context.palette.bgDivider, height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Category
                  const _SectionLabel('Category'),
                  const SizedBox(height: 6),
                  _buildDropdown<String?>(
                    value: _category,
                    hint: 'All Categories',
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...widget.categories.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)), // const not applicable (runtime value)
                      ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 14),

                  // AMC
                  const _SectionLabel('AMC'),
                  const SizedBox(height: 6),
                  _buildDropdown<String?>(
                    value: _amc,
                    hint: 'All AMCs',
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All AMCs')),
                      ...widget.amcs.map(
                        (a) => DropdownMenuItem(value: a, child: Text(a)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _amc = v),
                  ),
                  const SizedBox(height: 14),

                  // Plan type
                  const _SectionLabel('Plan Type'),
                  const SizedBox(height: 6),
                  SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(value: 'Direct', label: Text('Direct')),
                      ButtonSegment(value: 'Regular', label: Text('Regular')),
                    ],
                    selected: {_planType},
                    onSelectionChanged: (s) =>
                        setState(() => _planType = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return context.palette.bgSurface;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.textOnPrimary;
                        }
                        return context.palette.textSecondary;
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rating min
                  _SectionLabel('Minimum Rating: ${_ratingMin.round()} ★'),
                  Slider(
                    value: _ratingMin,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${_ratingMin.round()} ★',
                    activeColor: AppColors.primary,
                    inactiveColor: context.palette.bgSurface,
                    onChanged: (v) => setState(() => _ratingMin = v),
                  ),
                  const SizedBox(height: 10),

                  // ER max
                  const _SectionLabel('Max Expense Ratio (%)'),
                  const SizedBox(height: 6),
                  _buildTextField(context, _erMaxCtrl, '0.50'),
                  const SizedBox(height: 14),

                  // Return mins
                  const _SectionLabel('Min Returns (%)'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _labelledField(context, '1Y Min', _return1yCtrl, '10'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labelledField(context, '3Y Min', _return3yCtrl, '12'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labelledField(context, '5Y Min', _return5yCtrl, '14'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _labelledField(context, '3M Min', _return3mCtrl, '3'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labelledField(context, '6M Min', _return6mCtrl, '6'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labelledField(context, 
                          '3Y Info Ratio',
                          _infoRatio3yCtrl,
                          '0.3',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Riskometer
                  const _SectionLabel('Riskometer'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _riskLevels.map((level) {
                      final selected = _riskometer.contains(level);
                      return FilterChip(
                        label: Text(
                          level,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.textOnPrimary
                                : context.palette.textSecondary,
                          ),
                        ),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _riskometer.add(level);
                          } else {
                            _riskometer.remove(level);
                          }
                        }),
                        selectedColor: AppColors.primary,
                        backgroundColor: context.palette.bgSurface,
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Benchmark contains
                  const _SectionLabel('Benchmark contains'),
                  const SizedBox(height: 6),
                  _buildTextField(context, _benchmarkCtrl, 'e.g. NIFTY 100'),
                  const SizedBox(height: 14),

                  // AUM range
                  const _SectionLabel('AUM Range (₹ Cr)'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _labelledField(context, 'Min AUM', _aumMinCtrl, '500'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labelledField(context, 'Max AUM', _aumMaxCtrl, '50000'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => widget.onApply(_buildFilters()),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: TextStyle(color: context.palette.textTertiary)),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: context.palette.bgCardElevated,
        style: TextStyle(fontSize: 13, color: context.palette.textPrimary),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: 13, color: context.palette.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.palette.textTertiary),
        filled: true,
        fillColor: context.palette.bgSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _labelledField(BuildContext context, String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
        ),
        const SizedBox(height: 4),
        _buildTextField(context, ctrl, hint),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.palette.textSecondary,
      ),
    );
  }
}
