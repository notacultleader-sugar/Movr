import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/move.dart';
import '../theme.dart';
import 'live_backend.dart';

/// Rough driving time: straight line x road factor at ~40 km/h in town.
int etaMinutes(LatLng from, LatLng to) {
  final km = metersBetween(from, to) * 1.3 / 1000;
  return (km / 40 * 60).ceil().clamp(1, 600);
}

/// Opens turn-by-turn directions in the phone's maps app.
Future<void> openDirections(LatLng to) => launchUrl(
  Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${to.latitude},${to.longitude}&travelmode=driving',
  ),
  mode: LaunchMode.externalApplication,
);

/// A phone number people can tap to call (and read, in case the tap
/// doesn't open the dialler).
class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.phone, this.label});
  final String phone;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return OutlinedButton.icon(
      onPressed: digits.isEmpty
          ? null
          : () => launchUrl(Uri.parse('tel:$digits')),
      icon: const Icon(Icons.call, color: MovrColors.orange),
      label: Text(label ?? phone),
    );
  }
}

/// Vertical status list for a live job.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.job, this.etaToPickup});
  final LiveJob job;
  final int? etaToPickup;

  @override
  Widget build(BuildContext context) {
    final who = job.quote.vehicle.laborOnly ? 'Helpers' : 'Driver';
    final steps = <(JobStatus, String)>[
      (JobStatus.requested, 'Request sent'),
      (
        JobStatus.accepted,
        etaToPickup != null && job.status == JobStatus.accepted
            ? '$who on the way (about $etaToPickup min)'
            : '$who on the way',
      ),
      (JobStatus.atPickup, 'Loading at pickup'),
      (JobStatus.loaded, 'In transit to drop-off'),
      (JobStatus.delivered, 'Delivered'),
    ];
    final current = job.status.index;
    return Column(
      children: [
        for (final (i, (status, label)) in steps.indexed)
          _Step(
            label: label,
            done: status.index < current,
            active: status.index == current,
            last: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.done,
    required this.active,
    required this.last,
  });
  final String label;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? MovrColors.success
        : active
        ? MovrColors.orange
        : MovrColors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done || active ? color : MovrColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2.5,
                    color: done ? MovrColors.success : MovrColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: done || active ? MovrColors.black : MovrColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Charcoal banner saying this is the pilot, not the demo.
class PilotBadge extends StatelessWidget {
  const PilotBadge({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: MovrColors.black,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(radius: 4, backgroundColor: MovrColors.orange),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
