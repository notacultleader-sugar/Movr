import 'package:flutter/material.dart';

import '../theme.dart';
import 'live_backend.dart';
import 'live_driver_home.dart';

/// Pilot drivers sign in with the email and password the movr team set up
/// for them. (Open sign-up comes later, with real background checks.)
class LiveDriverSignInScreen extends StatefulWidget {
  const LiveDriverSignInScreen({super.key});

  @override
  State<LiveDriverSignInScreen> createState() => _LiveDriverSignInScreenState();
}

class _LiveDriverSignInScreenState extends State<LiveDriverSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resume();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Skip the form if this phone is already signed in as a driver.
  Future<void> _resume() async {
    DriverProfile? me;
    try {
      me = await LiveBackend.instance.currentDriver();
    } catch (_) {}
    if (!mounted) return;
    if (me != null) {
      _open(me);
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final me = await LiveBackend.instance.signInDriver(
        _email.text,
        _password.text,
      );
      if (mounted) _open(me);
    } on DriverSignInError catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Couldn\'t sign in. Check your connection and try again.';
      });
    }
  }

  void _open(DriverProfile me) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LiveDriverHome(me: me)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Driver sign in')),
      body: _busy && _error == null && _email.text.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: MovrColors.orange),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Welcome back.', style: text.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Use the email and password the movr team gave you.',
                  style: text.bodyMedium?.copyWith(color: MovrColors.textMuted),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('driver-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('driver-password'),
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) => _signIn(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
    );
  }
}
