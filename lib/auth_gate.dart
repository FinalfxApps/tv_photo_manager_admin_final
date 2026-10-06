import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'tenant_scope.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          TenantSession.clear();
          return const LoginScreen();
        }

        return _SessionResolver(
          key: ValueKey(user.uid),
          child: child,
        );
      },
    );
  }
}

class _SessionResolver extends StatefulWidget {
  const _SessionResolver({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<_SessionResolver> createState() => _SessionResolverState();
}

class _SessionResolverState extends State<_SessionResolver> {
  late Future<void> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = TenantSession.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingScreen();
        }

        if (snapshot.hasError) {
          return const _WorkspaceUnavailableScreen();
        }

        return widget.child;
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF07090E),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _WorkspaceUnavailableScreen extends StatelessWidget {
  const _WorkspaceUnavailableScreen();

  Future<void> _logout() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
    } catch (_) {}
    TenantSession.clear();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Center(
        child: Card(
          color: const Color(0xFF11141B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0x12FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_center_rounded,
                  size: 54,
                  color: Color(0xFFA996FF),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Workspace unavailable',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This account is not linked to a Final FX TV workspace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: .52),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _emailForUsername(String value) {
    final text = value.trim().toLowerCase();

    // Customer-facing username. Firebase Auth still receives an
    // email-shaped identifier internally; the customer never needs to
    // know or enter it.
    if (text == 'admin') {
      return 'admin@final-fx-tv.com';
    }

    return text.contains('@') ? text : '$text@final-fx-tv.com';
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Username or password is incorrect.';

      if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your connection.';
      }

      if (mounted) {
        setState(() => _error = message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign in right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: const Color(0xFF11141B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0x12FFFFFF)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8E72FF),
                            Color(0xFF5C3DF5),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.tv_rounded,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'FINAL FX TV',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your workspace',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: .52),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'customer username',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFE05252),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _login,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          _loading ? 'Signing in...' : 'LOGIN',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
