import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'active_move_screen.dart';
import 'plan_move_sheet.dart';
import 'scanner_screen.dart';

/// Stage 2: The Quote. The user builds their move: scan items, pick a
/// vehicle, see the price update live, then book.
class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key, required this.plan});
  final MovePlan plan;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  late Quote _quote = Quote(
    vehicle: VehicleTier.haul,
    items: List.of(widget.plan.items),
    miles: routeMiles(widget.plan.pickup.pos, widget.plan.dropoff.pos),
  );
  bool _vehicleChosen = false;
  bool _showBreakdown = false;

  int get _step => _quote.items.isEmpty ? 0 : (_vehicleChosen ? 2 : 1);

  bool get _vanRecommended =>
      _quote.items.length >= 4 ||
      _quote.items.any((i) => i.weightClass == WeightClass.extraHeavy) ||
      _quote.items.where((i) => i.weightClass == WeightClass.heavy).length >= 2;

  Future<void> _scan() async {
    final item = await Navigator.of(context).push<MoveItem>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScannerScreen(skip: _quote.items.length),
      ),
    );
    if (item != null) {
      setState(() => _quote = _quote.copyWith(items: [..._quote.items, item]));
    }
  }

  Future<void> _addManually() async {
    final item = await showModalBottomSheet<MoveItem>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              'Add an item',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            for (final i in scannableItems)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(i.icon),
                title: Text(i.name),
                subtitle: Text(
                  '${i.weightClass.label} · ${i.weightClass.range}',
                ),
                trailing: Text('+${money(i.weightClass.surcharge)}'),
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (item != null) {
      setState(() => _quote = _quote.copyWith(items: [..._quote.items, item]));
    }
  }

  Future<void> _book() async {
    setState(() => _vehicleChosen = true);
    final driver = drivers[_quote.vehicle]!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FindingDriverDialog(
        driver: driver,
        laborOnly: _quote.vehicle.laborOnly,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ActiveMoveScreen(
          order: MoveOrder(
            pickup: widget.plan.pickup,
            dropoff: widget.plan.dropoff,
            quote: _quote,
            driver: driver,
            driverStart: driverStartFor(widget.plan.pickup.pos),
          ),
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Build your move')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _ProgressBar(step: _step),
          const SizedBox(height: 16),
          MovrCard(
            child: RouteSummary(
              pickup: widget.plan.pickup.name == currentLocation.name
                  ? currentLocation.address
                  : '${widget.plan.pickup.name}, ${widget.plan.pickup.address}',
              dropoff:
                  '${widget.plan.dropoff.name}, ${widget.plan.dropoff.address}',
              trailing: Text(
                '${_quote.miles.toStringAsFixed(1)} mi',
                style: text.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('1. Items', style: text.titleLarge),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: FilledButton(
              onPressed: _scan,
              style: FilledButton.styleFrom(backgroundColor: MovrColors.black),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera, size: 34),
                  SizedBox(height: 8),
                  Text('Scan Items with AI', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, item) in _quote.items.indexed)
                InputChip(
                  avatar: Icon(item.icon, size: 18),
                  label: Text('${item.name} · ${item.weightClass.label}'),
                  onDeleted: () => setState(() {
                    final items = List.of(_quote.items)..removeAt(i);
                    _quote = _quote.copyWith(items: items);
                  }),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add manually'),
                onPressed: _addManually,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('2. Vehicle or help', style: text.titleLarge),
              const Spacer(),
              if (_vanRecommended && _quote.vehicle == VehicleTier.haul)
                Text(
                  'Van recommended for this load',
                  style: text.bodySmall?.copyWith(color: MovrColors.orange),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: Row(
              children: [
                for (final tier in VehicleTier.values) ...[
                  if (tier != VehicleTier.values.first)
                    const SizedBox(width: 10),
                  Expanded(
                    child: _VehicleCard(
                      tier: tier,
                      selected: _quote.vehicle == tier,
                      onTap: () => setState(() {
                        _quote = _quote.copyWith(vehicle: tier);
                        _vehicleChosen = true;
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_quote.vehicle.laborOnly) ...[
            const SizedBox(height: 12),
            _Stepper(
              label: 'Helpers',
              value: _quote.helpers,
              min: 1,
              max: 4,
              onChanged: (v) =>
                  setState(() => _quote = _quote.copyWith(helpers: v)),
            ),
            _Stepper(
              label: 'Hours',
              value: _quote.hours,
              min: 1,
              max: 8,
              onChanged: (v) =>
                  setState(() => _quote = _quote.copyWith(hours: v)),
            ),
            Text(
              'You drive; helpers meet you at pickup and ride along to unload.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _showBreakdown = !_showBreakdown),
            child: Row(
              children: [
                Text('Price breakdown', style: text.bodySmall),
                Icon(
                  _showBreakdown ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: MovrColors.textMuted,
                ),
              ],
            ),
          ),
          if (_showBreakdown) ...[
            const SizedBox(height: 8),
            if (_quote.vehicle.laborOnly)
              _line(
                '${_quote.helpers} helper(s) × ${_quote.hours} hr × '
                '${money(_quote.vehicle.basePrice)}',
                _quote.basePrice,
              )
            else ...[
              _line(
                '${_quote.vehicle.name} base (first ${Quote.includedMiles.toInt()} mi)',
                _quote.basePrice,
              ),
              _line('Item handling (${_quote.items.length})', _quote.itemsFee),
            ],
            if (_quote.distanceFee > 0)
              _line('Extra distance', _quote.distanceFee),
            _line('Safety fee (insurance + checks)', Quote.safetyFee),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: MovrColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: text.bodySmall),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Text(
                        money(_quote.total),
                        key: ValueKey(_quote.total),
                        style: const TextStyle(
                          fontFamily: kHeadingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                          color: MovrColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: FilledButton(
                  onPressed: _book,
                  style: FilledButton.styleFrom(
                    backgroundColor: MovrColors.black,
                  ),
                  child: const Text('Book move'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(money(amount)),
      ],
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Item', 'Vehicle', 'Book'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 6 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= step ? MovrColors.orange : MovrColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${i + 1}. ${labels[i]}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: i <= step
                          ? MovrColors.black
                          : MovrColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.tier,
    required this.selected,
    required this.onTap,
  });
  final VehicleTier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : MovrColors.black;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? MovrColors.black : MovrColors.surface,
          borderRadius: kBorderRadius,
          border: Border.all(
            color: selected ? MovrColors.orange : MovrColors.line,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  switch (tier) {
                    VehicleTier.haul => Icons.local_shipping,
                    VehicleTier.van => Icons.airport_shuttle,
                    VehicleTier.muscle => Icons.fitness_center,
                  },
                  color: fg,
                  size: 26,
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle, color: MovrColors.orange),
              ],
            ),
            const Spacer(),
            Text(
              tier.name,
              style: TextStyle(
                fontFamily: kHeadingFont,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: fg,
              ),
            ),
            Text(
              tier.priceLabel,
              style: const TextStyle(
                color: MovrColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(tier.vehicleType, style: TextStyle(fontSize: 12, color: fg)),
            const SizedBox(height: 4),
            Text(
              tier.tagline,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white70 : MovrColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingDriverDialog extends StatefulWidget {
  const _FindingDriverDialog({required this.driver, this.laborOnly = false});
  final Driver driver;
  final bool laborOnly;

  @override
  State<_FindingDriverDialog> createState() => _FindingDriverDialogState();
}

class _FindingDriverDialogState extends State<_FindingDriverDialog> {
  bool _found = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _found = true);
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: _found
                  ? const Icon(
                      Icons.check_circle,
                      color: MovrColors.orange,
                      size: 56,
                    )
                  : const CircularProgressIndicator(color: MovrColors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              _found
                  ? '${widget.driver.name} accepted!'
                  : widget.laborOnly
                  ? 'Finding helpers nearby…'
                  : 'Finding the nearest truck…',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _found
                  ? '${widget.driver.vehicle} · 4 min away'
                  : 'Matching you by GPS',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A "Helpers: [-] 2 [+]" row for the Muscle tier.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          tooltip: 'Fewer $label',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        IconButton(
          tooltip: 'More $label',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline, color: MovrColors.orange),
        ),
      ],
    );
  }
}
