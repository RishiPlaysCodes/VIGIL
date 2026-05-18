import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'home_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController(text: 'riya');
  final _passwordController = TextEditingController(text: 'safe-pass-123');
  final _api = ApiService();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = preferences.getInt('backend_user_id');
    final username = preferences.getString('username');
    final token = preferences.getString('api_token');
    if (!mounted || userId == null || username == null || token == null) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeShell(
          userId: userId,
          username: username,
          token: token,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = createAccount
          ? await _api.signUp(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            )
          : await _api.login(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('backend_user_id', result['id'] as int);
      await preferences.setString('username', result['username'] as String);
      await preferences.setString('api_token', result['token'] as String);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeShell(
            userId: result['id'] as int,
            username: result['username'] as String,
            token: result['token'] as String,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not connect. Check backend and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF082F49)]
                : const [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFCCFBF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pocket Guardian',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Travel safer with smart anti-theft protection.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : () => _submit(createAccount: false),
                    child: Text(_isLoading ? 'Please wait...' : 'Sign in'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => _submit(createAccount: true),
                    child: const Text('Create account'),
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
