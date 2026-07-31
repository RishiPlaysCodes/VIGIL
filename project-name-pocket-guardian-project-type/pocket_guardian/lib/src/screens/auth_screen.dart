import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import 'home_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();
  final _secureStorage = SecureStorageService.instance;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    // Wake the backend early so login is fast when the user submits.
    _api.warmUp();
  }

  Future<void> _restoreSession() async {
    final session = await _secureStorage.getAuthSession();
    if (!mounted || session.userId == null || session.username == null || session.token == null) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeShell(
          userId: session.userId!,
          username: session.username!,
          token: session.token!,
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
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Client-side validation
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }
    if (username.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters.');
      return;
    }
    if (createAccount && password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = createAccount
          ? await _api.signUp(username: username, password: password)
          : await _api.login(username: username, password: password);

      await _secureStorage.saveAuthSession(
        userId: result['id'] as int,
        username: result['username'] as String,
        token: result['token'] as String,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeShell(
            userId: result['id'] as int,
            username: result['username'] as String,
            token: result['token'] as String,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Server is waking up. Please wait 30 seconds and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Connecting to server... first launch can take up to a minute.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
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
