import 'package:flutter/material.dart';

import '../live/live_backend.dart';
import '../models/move.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Stage 4: Completion & Review. Confirms the charge, collects a tip for
/// the driver and a rating with quick tags.
class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key, required this.order});
  final MoveOrder order;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  static const _tags = ['Careful', 'On-Time', 'Heavy Lifter', 'Great Truck'];

  double? _tip;
  bool _customTip = false;
  int _stars = 0;
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _askCustomTip() async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        title: const Text('Custom tip'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: '0.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Add tip'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value > 0) {
      setState(() {
        _tip = value;
        _customTip = true;
      });
    }
  }

  void _submit() {
    final driver = widget.order.driver.name;
    final tip = _tip == null
        ? ''
        : ' Your ${money(_tip!)} tip goes 100% to $driver.';
    showDemoNote(context, 'Thanks for moving with movr!$tip');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final order = widget.order;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: MovrColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MovrColors.orange.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Move Complete!',
              textAlign: TextAlign.center,
              style: text.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${order.driver.name} dropped everything off at ${order.dropoff.name}.',
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            const SizedBox(height: 20),
            MovrCard(
              child: Column(
                children: [
                  _row('Total', money(order.quote.total), bold: true),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LiveBackend.enabled
                            ? Icons.payments_outlined
                            : Icons.credit_card,
                        size: 16,
                        color: MovrColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LiveBackend.enabled
                            ? 'Paid to your driver directly'
                            : 'Charged to Visa ****4242',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: MovrColors.line),
                  _row(
                    'Distance',
                    '${order.quote.miles.toStringAsFixed(1)} miles',
                  ),
                  const SizedBox(height: 6),
                  _row(
                    'Vehicle',
                    '${order.quote.vehicle.name} · ${order.driver.vehicle}',
                  ),
                  if (_tip != null) ...[
                    const SizedBox(height: 6),
                    _row('Tip', money(_tip!)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Add a tip for ${order.driver.name}', style: text.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final amount in const [5.0, 10.0, 15.0]) ...[
                  Expanded(
                    child: _TipButton(
                      label: '\$${amount.toInt()}',
                      selected: !_customTip && _tip == amount,
                      onTap: () => setState(() {
                        _customTip = false;
                        _tip = _tip == amount ? null : amount;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _TipButton(
                    label: _customTip ? money(_tip!) : 'Custom',
                    selected: _customTip,
                    onTap: _askCustomTip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'How was your move?',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 44,
                    tooltip: '$i star${i == 1 ? '' : 's'}',
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i <= _stars
                          ? MovrColors.orange
                          : MovrColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _tags)
                  FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _selectedTags.contains(tag)
                          ? Colors.white
                          : MovrColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (on) => setState(
                      () => on
                          ? _selectedTags.add(tag)
                          : _selectedTags.remove(tag),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _stars == 0 ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: MovrColors.black),
              child: Text(_stars == 0 ? 'Tap a star to rate' : 'Submit review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: bold ? 18 : 14,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 22 : 14,
            fontFamily: bold ? kHeadingFont : kBodyFont,
            color: bold ? MovrColors.orange : MovrColors.black,
          ),
        ),
      ),
    ],
  );
}

class _TipButton extends StatelessWidget {
  const _TipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: selected ? MovrColors.black : MovrColors.orange,
      minimumSize: const Size.fromHeight(60),
      padding: EdgeInsets.zero,
      side: selected
          ? const BorderSide(color: MovrColors.orange, width: 2.5)
          : null,
      textStyle: const TextStyle(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    ),
    child: Text(label),
  );
}
