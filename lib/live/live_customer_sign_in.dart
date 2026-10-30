import 'package:flutter/material.dart';

import '../theme.dart';
import 'live_backend.dart';

/// Shows the customer sign-in screen unless someone is already signed in.
/// Returns true once signed in.
Future<bool> ensureCustomerSignedIn(BuildContext context) async {
  if (LiveBackend.instance.customer != null) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LiveCustomerSignInScreen()),
  );
  return ok ?? false;
}

/// Customers sign in with Google, or with an email and password (signing
/// in or creating an account), before they book.
class LiveCustomerSignInScreen extends StatefulWidget {
  const LiveCustomerSignInScreen({super.key});

  @override
  State<LiveCustomerSignInScreen> createState() =>
      _LiveCustomerSignInScreenState();
}

class _LiveCustomerSignInScreenState extends State<LiveCustomerSignInScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } on AccountError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Couldn\'t sign in. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _google() => _run(LiveBackend.instance.signInWithGoogle);

  void _submit() {
    if (_creating && _name.text.trim().isEmpty) {
      setState(
        () => _error = 'Add your name so the driver knows who to ask for.',
      );
      return;
    }
    _run(
      () => _creating
          ? LiveBackend.instance.createCustomer(
              _name.text,
              _email.text,
              _password.text,
            )
          : LiveBackend.instance.signInCustomer(_email.text, _password.text),
    );
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Type your email first, then tap this again.');
      return;
    }
    setState(() {
      _error = null;
      _notice = null;
    });
    try {
      await LiveBackend.instance.sendPasswordReset(_email.text);
      if (mounted) {
        setState(() => _notice = 'Check your email for a reset link.');
      }
    } on AccountError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_creating ? 'Create account' : 'Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _creating ? 'Book your first move.' : 'Sign in to book.',
            style: text.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Your account keeps your bookings and lets you follow your '
            'driver on any phone.',
            style: text.bodyMedium?.copyWith(color: MovrColors.textMuted),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _busy ? null : _google,
            icon: const Text(
              'G',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: MovrColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('or with email', style: text.bodySmall),
              ),
              const Expanded(child: Divider(color: MovrColors.line)),
            ],
          ),
          const SizedBox(height: 16),
          if (_creating) ...[
            TextField(
              key: const ValueKey('account-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            key: const ValueKey('account-email'),
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
            key: const ValueKey('account-password'),
            controller: _password,
            obscureText: true,
            autofillHints: [
              _creating ? AutofillHints.newPassword : AutofillHints.password,
            ],
            decoration: InputDecoration(
              labelText: _creating ? 'Choose a password' : 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(_notice!, style: text.bodyMedium),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(_creating ? 'Create account' : 'Sign in'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _creating = !_creating;
                    _error = null;
                    _notice = null;
                  }),
            child: Text(
              _creating
                  ? 'Already have an account? Sign in'
                  : 'New to movr? Create an account',
            ),
          ),
          if (!_creating)
            TextButton(
              onPressed: _busy ? null : _reset,
              child: const Text('Forgot password?'),
            ),
        ],
      ),
    );
  }
}
