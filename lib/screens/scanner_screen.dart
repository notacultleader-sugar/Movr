import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import '../theme.dart';

/// The "Scan Items with AI" camera view.
///
/// Prototype: the camera feed and detection are simulated. Each scan returns
/// the next item from [scannableItems] with its weight class. A production
/// build would run an on-device vision model (or a cloud vision API) on the
/// camera frames and map the detected label to a [WeightClass].
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.skip = 0});

  /// How many items have already been scanned, so repeat scans vary.
  final int skip;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late int _index = widget.skip;
  MoveItem? _detected;

  MoveItem get _candidate => scannableItems[_index % scannableItems.length];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() => _detected = null);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _detected = _candidate);
    });
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'AI Item Scan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Stack(
                      children: [
                        // Simulated camera feed: a soft gradient with the item silhouette.
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: kBorderRadius,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF3A3A3A), Color(0xFF1C1C1C)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _candidate.icon,
                            size: c.maxWidth * 0.5,
                            color: Colors.white24,
                          ),
                        ),
                        const Positioned.fill(
                          child: CustomPaint(painter: _CornersPainter()),
                        ),
                        if (_detected == null)
                          AnimatedBuilder(
                            animation: _sweep,
                            builder: (context, _) => Positioned(
                              left: 16,
                              right: 16,
                              top: 16 + (c.maxHeight - 32) * _sweep.value,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: MovrColors.orange,
                                  boxShadow: [
                                    BoxShadow(
                                      color: MovrColors.orange.withValues(
                                        alpha: 0.7,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _detected == null
                                    ? 'Point your camera at the item…'
                                    : 'Item identified',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _detected == null
                  ? const SizedBox(
                      height: 210,
                      child: Center(
                        child: Text(
                          'Demo: detection is simulated',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  : _ResultCard(
                      item: _detected!,
                      onAdd: () => Navigator.pop(context, _detected),
                      onRescan: () {
                        _index++;
                        _startScan();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.item,
    required this.onAdd,
    required this.onRescan,
  });
  final MoveItem item;
  final VoidCallback onAdd;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MovrColors.surface,
        borderRadius: kBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MovrColors.orangeTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: MovrColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${item.weightClass.label} · ${item.weightClass.range} · 94% match',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '+${money(item.weightClass.surcharge)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: MovrColors.orange,
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton(onPressed: onAdd, child: const Text('Add to my move')),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: onRescan,
              child: const Text('Not right? Scan again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MovrColors.orange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 36.0, m = 14.0;
    final r = (Offset.zero & size).deflate(m);
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner + Offset(l * dx, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, l * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}
