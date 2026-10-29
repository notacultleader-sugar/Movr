import 'package:flutter/material.dart';

import '../models/move.dart';
import '../theme.dart';
import 'live_backend.dart';
import 'live_session.dart';
import 'live_tracking_screen.dart';

/// Pilot booking: asks who the driver should contact, sends the request,
/// and opens live tracking.
Future<void> bookLiveMove(
  BuildContext context, {
  required Place pickup,
  required Place dropoff,
  required Quote quote,
}) async {
  final contact = await showModalBottomSheet<_Contact>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ContactSheet(total: quote.total),
  );
  if (contact == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: MovrColors.orange),
    ),
  );
  try {
    final id = await LiveBackend.instance.createJob(
      pickup: pickup,
      dropoff: dropoff,
      quote: quote,
      contactName: contact.name,
      contactPhone: contact.phone,
      notes: contact.notes,
    );
    await LiveSession.setActiveJob(id);
    navigator.pop();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LiveTrackingScreen(jobId: id)),
      (route) => route.isFirst,
    );
  } catch (e) {
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Couldn\'t send your request. Check your connection and try again.',
        ),
      ),
    );
  }
}

class _Contact {
  const _Contact(this.name, this.phone, this.notes);
  final String name;
  final String phone;
  final String notes;
}

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({required this.total});
  final double total;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  bool get _ready =>
      _name.text.trim().isNotEmpty &&
      _phone.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 10;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Who should the driver contact?', style: text.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('contact-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('contact-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('contact-notes'),
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes for the driver (optional)',
                hintText: 'Buzzer, stairs, which door…',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MovrColors.orangeTint,
                borderRadius: kBorderRadius,
              ),
              child: Text(
                'Pilot: pay the driver ${money(widget.total)} directly when '
                'the move is done. No card is charged in the app yet.',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _ready
                  ? () => Navigator.pop(
                      context,
                      _Contact(_name.text, _phone.text, _notes.text),
                    )
                  : null,
              child: const Text('Request driver'),
            ),
          ],
        ),
      ),
    );
  }
}
