import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import '../live/live_backend.dart';
import '../live/live_config.dart';
import '../services/geocoding.dart';
import '../services/location.dart';
import '../theme.dart';

/// Result of the planning sheet: where from, where to, and any items we
/// already know about (e.g. from a Marketplace listing).
class MovePlan {
  const MovePlan(this.pickup, this.dropoff, this.items);
  final Place pickup;
  final Place dropoff;
  final List<MoveItem> items;
}

Future<MovePlan?> showPlanMoveSheet(
  BuildContext context, {
  Place? pickup,
  Place? dropoff,
  List<MoveItem> items = const [],
}) {
  return showModalBottomSheet<MovePlan>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PlanMoveSheet(
      // Live mode has no sample "current location": the person searches
      // or uses their phone's GPS.
      pickup: pickup ?? (LiveBackend.enabled ? null : currentLocation),
      dropoff: dropoff,
      items: items,
    ),
  );
}

enum _Field { pickup, dropoff }

class _PlanMoveSheet extends StatefulWidget {
  const _PlanMoveSheet({this.pickup, this.dropoff, required this.items});
  final Place? pickup;
  final Place? dropoff;
  final List<MoveItem> items;

  @override
  State<_PlanMoveSheet> createState() => _PlanMoveSheetState();
}

class _PlanMoveSheetState extends State<_PlanMoveSheet> {
  late Place? _pickup = widget.pickup;
  late Place? _dropoff = widget.dropoff;
  late _Field _active = _pickup == null
      ? _Field.pickup
      : (_dropoff == null ? _Field.dropoff : _Field.pickup);
  String _query = '';

  // Real addresses from the map service, for whatever was typed.
  List<Place> _found = const [];
  bool _searching = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    setState(() {
      _query = v;
      _found = const [];
      _searching = v.trim().length >= 3;
    });
    _debounce?.cancel();
    if (v.trim().length < 3) return;
    // Wait for a pause in typing: the free service allows ~1 request/sec.
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final results = await Geocoding.instance.search(v);
      if (!mounted || v != _query) return;
      setState(() {
        _found = results;
        _searching = false;
      });
    });
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final pos = await DeviceLocation.current();
    final place = pos == null
        ? null
        : await Geocoding.instance.reverse(pos) ??
              Place('Current location', 'Pinned on the map', pos);
    if (!mounted) return;
    setState(() => _locating = false);
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Couldn\'t get your location. Allow location access, or search '
            'for the address.',
          ),
        ),
      );
      return;
    }
    _select(place);
  }

  List<Place> get _options {
    final all = LiveBackend.enabled
        ? [...pilotStores.map((s) => s.place)]
        : [
            if (_active == _Field.pickup) currentLocation,
            ...suggestedPlaces,
            ...partnerStores.map((s) => s.place),
          ];
    final q = _query.toLowerCase();
    return all
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q),
        )
        .toList();
  }

  void _select(Place place) {
    setState(() {
      if (_active == _Field.pickup) {
        _pickup = place;
        if (_dropoff == null) _active = _Field.dropoff;
      } else {
        _dropoff = place;
      }
      _query = '';
      _found = const [];
      _searching = false;
    });
    _debounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ready = _pickup != null && _dropoff != null && _pickup != _dropoff;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan your move', style: text.headlineSmall),
              const SizedBox(height: 16),
              _fieldTile(
                _Field.pickup,
                Icons.circle,
                MovrColors.black,
                'Pickup',
                _pickup,
              ),
              const SizedBox(height: 8),
              _fieldTile(
                _Field.dropoff,
                Icons.location_on,
                MovrColors.orange,
                'Where are we moving to?',
                _dropoff,
              ),
              const SizedBox(height: 12),
              TextField(
                key: ValueKey(_active),
                autofocus: false,
                decoration: InputDecoration(
                  hintText: _active == _Field.pickup
                      ? 'Search pickup address'
                      : 'Search drop-off address',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onQuery,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_active == _Field.pickup && _query.isEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _locating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: MovrColors.orange,
                              ),
                        title: Text(
                          'Use my current location',
                          style: text.titleMedium,
                        ),
                        subtitle: const Text('From your phone\'s GPS'),
                        onTap: _locating ? null : _useMyLocation,
                      ),
                    for (final p in _found)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.travel_explore,
                          color: MovrColors.textMuted,
                        ),
                        title: Text(p.name, style: text.titleMedium),
                        subtitle: Text(p.address),
                        onTap: () => _select(p),
                      ),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    for (final p in _options)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          p == recentDropoff
                              ? Icons.history
                              : Icons.place_outlined,
                          color: MovrColors.textMuted,
                        ),
                        title: Text(p.name, style: text.titleMedium),
                        subtitle: Text(p.address),
                        onTap: () => _select(p),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: ready
                    ? () => Navigator.pop(
                        context,
                        MovePlan(_pickup!, _dropoff!, widget.items),
                      )
                    : null,
                child: const Text('Get my quote'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldTile(
    _Field field,
    IconData icon,
    Color color,
    String hint,
    Place? value,
  ) {
    final active = _active == field;
    return InkWell(
      borderRadius: kBorderRadius,
      onTap: () => setState(() {
        _active = field;
        _query = '';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MovrColors.background,
          borderRadius: kBorderRadius,
          border: Border.all(
            color: active ? MovrColors.orange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: field == _Field.pickup ? 12 : 20, color: color),
            SizedBox(width: field == _Field.pickup ? 16 : 10),
            Expanded(
              child: value == null
                  ? Text(
                      hint,
                      style: const TextStyle(
                        color: MovrColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          value.address,
                          style: const TextStyle(
                            color: MovrColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
