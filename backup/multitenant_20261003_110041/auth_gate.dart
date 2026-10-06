import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: const Color(0xFF07090E),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        return child;
      },
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
    final text = value.trim();

    if (text.contains('@')) {
      return text;
    }

    if (text.toLowerCase() == 'admin') {
      return 'admin@final-fx-tv.com';
    }

    return '$text@final-fx-tv.com';
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
      String message = 'Login failed. Please check your details.';

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Username or password is incorrect.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
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

  Future<void> _forgotPassword() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() => _error = 'Enter your username first.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailForUsername(username),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.code == 'user-not-found'
              ? 'No account found for this username.'
              : 'Could not send password reset email.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send password reset email.');
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
                side: const BorderSide(color: const Color(0x12FFFFFF)),
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
                          colors: [Color(0xFF8E72FF), Color(0xFF5C3DF5)],
                        ),
                      ),
                      child: const Icon(Icons.tv_rounded, size: 36),
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
                      'Administrator Login',
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
                        hintText: 'admin',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
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
                          color: const Color(0xFFE05252),
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
                        label: Text(_loading ? 'Signing in...' : 'LOGIN'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
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
