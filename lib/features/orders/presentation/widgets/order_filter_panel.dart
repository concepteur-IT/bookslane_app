import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/domain/entities/order_record.dart';
import 'package:bookslane_app/features/orders/presentation/order_format.dart';

typedef OrderFacetsLoader = Future<OrderFacets> Function(OrderFilters draft);

/// The Orders filter overlay: status, date (with quick ranges), order total
/// and discount. Like `DynamicFilterPanel`, it edits a draft that only
/// reaches the page on Apply, while the options and the "SHOW N ORDERS"
/// count stay live — every change re-asks the server (debounced) what that
/// selection leaves.
class OrderFilterPanel extends StatefulWidget {
  const OrderFilterPanel({
    super.key,
    required this.initial,
    required this.loadFacets,
    this.debounce = const Duration(milliseconds: 250),
  });

  final OrderFilters initial;
  final OrderFacetsLoader loadFacets;
  final Duration debounce;

  @override
  State<OrderFilterPanel> createState() => _OrderFilterPanelState();
}

class _OrderFilterPanelState extends State<OrderFilterPanel> {
  late OrderFilters _draft = widget.initial;

  OrderFacets? _facets;
  bool _loading = true;
  bool _failed = false;

  int _request = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final facets = await widget.loadFacets(_draft);
      if (!mounted || request != _request) return;
      setState(() {
        _facets = facets;
        _loading = false;
      });
    } on ApiFailure {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _change(OrderFilters next) {
    setState(() => _draft = next);
    _timer?.cancel();
    _timer = Timer(widget.debounce, _load);
  }

  void _reset() {
    _timer?.cancel();
    setState(() => _draft = OrderFilters.initial);
    _load();
  }

  void _toggleStatus(String value) {
    final next = {..._draft.statuses};
    next.contains(value) ? next.remove(value) : next.add(value);
    _change(_draft.copyWith(statuses: next));
  }

  void _toggleDiscount(bool value) => _change(
    _draft.hasDiscount == value
        ? _draft.copyWith(clearHasDiscount: true)
        : _draft.copyWith(hasDiscount: value),
  );

  void _setTotal(RangeValues values, ({double min, double max}) bounds) {
    final isFull = values.start <= bounds.min && values.end >= bounds.max;
    setState(() {
      _draft = isFull
          ? _draft.copyWith(clearTotalRange: true)
          : _draft.copyWith(
              totalRange: (
                min: values.start.roundToDouble(),
                max: values.end.roundToDouble(),
              ),
            );
    });
  }

  DayRange _lastDays(int days) {
    final today = DateTime.now();
    return DayRange(
      start: DateTime(today.year, today.month, today.day - (days - 1)),
      end: today,
    );
  }

  bool _sameDays(DayRange? a, DayRange b) =>
      a != null &&
      a.start.year == b.start.year &&
      a.start.month == b.start.month &&
      a.start.day == b.start.day &&
      a.end.year == b.end.year &&
      a.end.month == b.end.month &&
      a.end.day == b.end.day;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final placed = _facets?.placedRange;
    final current = _draft.dateRange;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: placed == null
          ? DateTime(now.year - 5)
          : DateTime(placed.start.year, placed.start.month, placed.start.day),
      lastDate: now,
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.start, end: current.end),
    );
    if (picked == null || !mounted) return;
    _change(
      _draft.copyWith(
        dateRange: DayRange(start: picked.start, end: picked.end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facets = _facets;
    final total = facets?.total;
    final isSettled = facets != null && !_loading && !_failed;

    return FilterPanelFrame(
      onReset: _draft.isInitial ? null : _reset,
      onApply: () => Navigator.of(context).pop(_draft),
      applyLabel: isSettled && total != null
          ? 'SHOW $total ${total == 1 ? 'ORDER' : 'ORDERS'}'
          : 'APPLY',
      sections: [
        AnimatedOpacity(
          opacity: _loading && facets != null ? 0.5 : 1,
          duration: AppDurations.fast,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._statusSection(facets),
              ..._dateSection(),
              ..._totalSection(facets),
              ..._discountSection(facets),
              if (_failed) _Failure(onRetry: _load),
              if (_loading && facets == null) const _Spinner(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _statusSection(OrderFacets? facets) {
    // Whatever is selected stays listed even if the other filters now leave
    // it with no orders, so it can be un-picked.
    final byValue = {for (final s in facets?.statuses ?? []) s.value: s.count};
    final values = {..._draft.statuses, ...byValue.keys}.toList();

    return [
      const PanelHeading('Status'),
      if (facets != null && values.isEmpty)
        const _Note('No orders yet.')
      else
        PanelChipWrap(
          children: [
            for (final value in values)
              ChoiceChipButton(
                dense: true,
                label: byValue.containsKey(value)
                    ? '${OrderRecord.labelForStatus(value)} · ${byValue[value]}'
                    : OrderRecord.labelForStatus(value),
                isSelected: _draft.statuses.contains(value),
                onPressed: () => _toggleStatus(value),
              ),
          ],
        ),
    ];
  }

  List<Widget> _dateSection() {
    final range = _draft.dateRange;
    final today = DateTime.now();
    final todayRange = DayRange(start: today, end: today);
    final week = _lastDays(7);
    final month = _lastDays(30);

    return [
      PanelHeading(
        'Date placed',
        trailing: range == null
            ? null
            : range.start == range.end
            ? formatDay(range.start)
            : '${formatDay(range.start)} – ${formatDay(range.end)}',
      ),
      PanelChipWrap(
        children: [
          ChoiceChipButton(
            dense: true,
            label: 'Today',
            isSelected: _sameDays(range, todayRange),
            onPressed: () => _change(
              _sameDays(range, todayRange)
                  ? _draft.copyWith(clearDateRange: true)
                  : _draft.copyWith(dateRange: todayRange),
            ),
          ),
          ChoiceChipButton(
            dense: true,
            label: 'Last 7 days',
            isSelected: _sameDays(range, week),
            onPressed: () => _change(
              _sameDays(range, week)
                  ? _draft.copyWith(clearDateRange: true)
                  : _draft.copyWith(dateRange: week),
            ),
          ),
          ChoiceChipButton(
            dense: true,
            label: 'Last 30 days',
            isSelected: _sameDays(range, month),
            onPressed: () => _change(
              _sameDays(range, month)
                  ? _draft.copyWith(clearDateRange: true)
                  : _draft.copyWith(dateRange: month),
            ),
          ),
          ChoiceChipButton(
            dense: true,
            label: 'Pick dates…',
            isSelected:
                range != null &&
                !_sameDays(range, todayRange) &&
                !_sameDays(range, week) &&
                !_sameDays(range, month),
            onPressed: _pickDates,
          ),
        ],
      ),
    ];
  }

  List<Widget> _totalSection(OrderFacets? facets) {
    final bounds = facets?.totalRange;
    final usable = bounds != null && bounds.max > bounds.min;

    final range = _draft.totalRange;
    final values = usable
        ? RangeValues(
            (range?.min ?? bounds.min).clamp(bounds.min, bounds.max),
            (range?.max ?? bounds.max).clamp(bounds.min, bounds.max),
          )
        : null;

    return [
      PanelHeading(
        'Order total',
        trailing: values == null
            ? null
            : '₹${values.start.round()} – ₹${values.end.round()}'
                  '${range == null ? '+' : ''}',
      ),
      if (usable && values != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: RangeSlider(
            values: values,
            min: bounds.min,
            max: bounds.max,
            activeColor: AppColors.brandPrimary,
            inactiveColor: AppColors.brandSoftBackground,
            onChanged: (v) => _setTotal(v, bounds),
            // One request when the thumb is let go, not one per pixel.
            onChangeEnd: (_) => _change(_draft),
          ),
        )
      else if (facets != null && !_loading)
        const _Note('No total range to choose from.'),
    ];
  }

  List<Widget> _discountSection(OrderFacets? facets) {
    String label(String name, int? count) =>
        count == null ? name : '$name · $count';

    return [
      const PanelHeading('Discount'),
      PanelChipWrap(
        children: [
          ChoiceChipButton(
            dense: true,
            label: label('With discount', facets?.withDiscount),
            isSelected: _draft.hasDiscount == true,
            onPressed: () => _toggleDiscount(true),
          ),
          ChoiceChipButton(
            dense: true,
            label: label('No discount', facets?.withoutDiscount),
            isSelected: _draft.hasDiscount == false,
            onPressed: () => _toggleDiscount(false),
          ),
        ],
      ),
    ];
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Text(text, style: AppTypography.caption),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Couldn’t load the options.',
            style: AppTypography.caption.copyWith(color: AppColors.errorText),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
