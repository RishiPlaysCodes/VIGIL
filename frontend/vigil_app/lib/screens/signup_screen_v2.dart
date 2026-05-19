import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../services/api_service.dart';

class SignupScreenV2 extends StatefulWidget {
  const SignupScreenV2({super.key});

  @override
  State<SignupScreenV2> createState() => _SignupScreenV2State();
}

class _SignupScreenV2State extends State<SignupScreenV2> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ApiService().register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const NeonPulse(size: 70, animate: true),
                const SizedBox(height: 20),
                const HoloText(
                  text: 'JOIN VIGIL',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Create your AI safety account',
                    style: VigilThemeV2.bodySM.copyWith(
                        color: VigilThemeV2.textMuted)),
                const SizedBox(height: 24),

                NeoGlassCard(
                  padding: const EdgeInsets.all(20),
                  showHoloBorder: true,
                  glowColor: VigilThemeV2.violetNeon,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(_usernameController, 'Username',
                            Icons.person_outline_rounded),
                        const SizedBox(height: 14),
                        _field(_emailController, 'Email',
                            Icons.email_outlined,
                            type: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            }),
                        const SizedBox(height: 14),
                        _field(_phoneController, 'Phone Number',
                            Icons.phone_outlined,
                            type: TextInputType.phone),
                        const SizedBox(height: 14),
                        _field(_passwordController, 'Password',
                            Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 8) return 'Min 8 characters';
                              return null;
                            }),
                        const SizedBox(height: 14),
                        _field(_confirmController, 'Confirm Password',
                            Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            }),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: VigilThemeV2.spaceBlack,
                                    ))
                                : const Text('CREATE ACCOUNT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: VigilThemeV2.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}
