import 'package:flutter/material.dart';

import '../../data/driver_data.dart';
import '../../theme.dart';
import 'driver_home_screen.dart';

/// Driver application: about you, vehicle, documents, safety checks, then
/// review. Requirements come from the recruitment ad: a pickup, cargo van or
/// box truck from 2014 or newer, able to lift 50+ lb, clean background check
/// and valid insurance.
///
/// Prototype: uploads and the background check are simulated.
class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  static const _steps = ['About you', 'Vehicle', 'Documents', 'Safety'];
  static const minYear = 2014;

  int _step = 0;

  final _name = TextEditingController(text: 'Jordan Lee');
  final _phone = TextEditingController(text: '(555) 014-3321');
  final _email = TextEditingController(text: 'jordan@example.com');
  final _make = TextEditingController(text: 'Toyota Tacoma');
  final _plate = TextEditingController(text: 'TRK-218');
  DriverVehicleType _type = DriverVehicleType.pickup;
  int _year = 2019;
  final Set<String> _uploaded = {};
  bool _canLift = false;
  bool _backgroundConsent = false;

  static const _documents = [
    ('Driver\'s licence', Icons.badge_outlined),
    ('Vehicle insurance', Icons.verified_user_outlined),
    ('Vehicle registration', Icons.description_outlined),
    ('Photo of your vehicle', Icons.photo_camera_outlined),
  ];

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _make, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _stepValid => switch (_step) {
    0 =>
      _name.text.trim().isNotEmpty &&
          _phone.text.trim().isNotEmpty &&
          _email.text.contains('@'),
    1 =>
      _year >= minYear &&
          _make.text.trim().isNotEmpty &&
          _plate.text.trim().isNotEmpty,
    2 => _uploaded.length == _documents.length,
    _ => _canLift && _backgroundConsent,
  };

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }
    driverSession.register(
      name: _name.text.trim().split(' ').first,
      type: _type,
      vehicle: '$_year ${_make.text.trim()}',
      plate: _plate.text.trim().toUpperCase(),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _ApplicationReview()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive with movr'),
        leading: BackButton(
          onPressed: () =>
              _step == 0 ? Navigator.pop(context) : setState(() => _step--),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (_step == 0) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MovrColors.black,
                borderRadius: kBorderRadius,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Put your truck to work.',
                    style: TextStyle(
                      fontFamily: kHeadingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Earn \$40–\$90/hour. Keep 100% of tips. Daily payouts. Drive when you want.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _StepBar(step: _step, labels: _steps),
          const SizedBox(height: 20),
          Text(_steps[_step], style: text.headlineSmall),
          const SizedBox(height: 14),
          ...switch (_step) {
            0 => _aboutYou(),
            1 => _vehicle(),
            2 => _docs(),
            _ => _safety(),
          },
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _stepValid ? _next : null,
            child: Text(
              _step == _steps.length - 1 ? 'Submit application' : 'Continue',
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _aboutYou() => [
    _field(_name, 'Full name', Icons.person_outline),
    _field(
      _phone,
      'Mobile number',
      Icons.phone_outlined,
      keyboard: TextInputType.phone,
    ),
    _field(
      _email,
      'Email',
      Icons.mail_outline,
      keyboard: TextInputType.emailAddress,
    ),
  ];

  List<Widget> _vehicle() => [
    const Text('Vehicle type', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Row(
      children: [
        for (final t in DriverVehicleType.values) ...[
          if (t != DriverVehicleType.values.first) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == t ? MovrColors.black : MovrColors.surface,
                  borderRadius: kBorderRadius,
                  border: Border.all(
                    color: _type == t ? MovrColors.orange : MovrColors.line,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      t.icon,
                      color: _type == t ? Colors.white : MovrColors.black,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _type == t ? Colors.white : MovrColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
    const SizedBox(height: 6),
    Text(
      _type == DriverVehicleType.pickup
          ? 'You\'ll get single items, appliances and Marketplace pickups.'
          : 'You\'ll get bigger loads too: studios, dorms and IKEA runs.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<int>(
      initialValue: _year,
      decoration: InputDecoration(
        labelText: 'Year',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        errorText: _year < minYear
            ? 'Vehicles must be $minYear or newer'
            : null,
      ),
      items: [
        for (var y = 2026; y >= 2008; y--)
          DropdownMenuItem(value: y, child: Text('$y')),
      ],
      onChanged: (y) => setState(() => _year = y ?? _year),
    ),
    const SizedBox(height: 12),
    _field(_make, 'Make and model', Icons.directions_car_outlined),
    _field(_plate, 'Licence plate', Icons.pin_outlined),
  ];

  List<Widget> _docs() => [
    Text(
      'Upload a clear photo of each. We check them within one business day.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    const SizedBox(height: 12),
    for (final (label, icon) in _documents)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: MovrColors.surface,
          borderRadius: kBorderRadius,
          child: InkWell(
            borderRadius: kBorderRadius,
            onTap: () => setState(
              () => _uploaded.contains(label)
                  ? _uploaded.remove(label)
                  : _uploaded.add(label),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _uploaded.contains(label)
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: MovrColors.success,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Uploaded',
                              style: TextStyle(
                                color: MovrColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Upload',
                          style: TextStyle(
                            color: MovrColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
  ];

  List<Widget> _safety() => [
    Text(
      'Every customer is verified and every move is insured up to \$15,000. We ask the same of drivers.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    const SizedBox(height: 8),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _canLift,
      onChanged: (v) => setState(() => _canLift = v ?? false),
      title: const Text('I can safely lift 50+ lb'),
    ),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _backgroundConsent,
      onChanged: (v) => setState(() => _backgroundConsent = v ?? false),
      title: const Text('I consent to a background check'),
      subtitle: const Text(
        'Criminal record and driving history. Covered by movr\'s safety fee.',
      ),
    ),
  ];

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < labels.length; i++)
        Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < labels.length - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: i <= step ? MovrColors.orange : MovrColors.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
    ],
  );
}

/// After submitting: documents received, background check runs, approved.
class _ApplicationReview extends StatefulWidget {
  const _ApplicationReview();

  @override
  State<_ApplicationReview> createState() => _ApplicationReviewState();
}

class _ApplicationReviewState extends State<_ApplicationReview> {
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _approved = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String label, bool done, String pending) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          done
              ? const Icon(Icons.check_circle, color: MovrColors.success)
              : const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: MovrColors.orange,
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              done ? label : pending,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(
                _approved ? Icons.verified : Icons.hourglass_top,
                size: 64,
                color: MovrColors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _approved
                    ? 'You\'re approved, ${driverSession.name}!'
                    : 'Application submitted',
                style: text.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _approved
                    ? 'Your ${driverSession.vehicle} is ready for ${driverSession.vehicleType.tier.name} jobs.'
                    : 'We\'re checking your documents and running your background check.',
                style: text.bodyMedium?.copyWith(color: MovrColors.textMuted),
              ),
              const SizedBox(height: 24),
              row('Documents received', true, ''),
              row(
                'Background check: clear',
                _approved,
                'Background check in progress…',
              ),
              row('Vehicle approved', _approved, 'Vehicle review in progress…'),
              const Spacer(),
              Text(
                'Demo: approval is instant. Real checks take 1–3 business days.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _approved
                    ? () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DriverHomeScreen(),
                        ),
                        (_) => false,
                      )
                    : null,
                child: const Text('Start driving'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
