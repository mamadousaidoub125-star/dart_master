import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Écran de connexion : email/mot de passe + connexion sociale
/// (Google, Apple), conformément aux exigences des deux stores
/// (Apple impose de proposer "Sign in with Apple" si Google est présent).
class LoginScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final void Function(AppUser user) onLoginSuccess;
  final VoidCallback onNavigateToSignUp;

  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
    required this.onNavigateToSignUp,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await widget.authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() => _errorMessage = 'Connexion impossible. Vérifiez vos identifiants.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialSignIn(Future<AppUser> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      final user = await signInMethod();
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() => _errorMessage = 'Connexion sociale impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 48),
                const Text(
                  'Content de te revoir',
                  style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connecte-toi pour retrouver ta progression',
                  style: TextStyle(color: AppColors.lightGray, fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Adresse email'),
                  validator: (value) =>
                      (value == null || !value.contains('@')) ? 'Adresse email invalide' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: AppColors.white),
                  obscureText: true,
                  decoration: _inputDecoration('Mot de passe'),
                  validator: (value) =>
                      (value == null || value.length < 6) ? '6 caractères minimum' : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.darkSurfaceElevated)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: AppColors.lightGray.withOpacity(0.7))),
                    ),
                    const Expanded(child: Divider(color: AppColors.darkSurfaceElevated)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _handleSocialSignIn(widget.authRepository.signInWithGoogle),
                  icon: const Icon(Icons.g_mobiledata, color: AppColors.white),
                  label: const Text('Continuer avec Google', style: TextStyle(color: AppColors.white)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _handleSocialSignIn(widget.authRepository.signInWithApple),
                  icon: const Icon(Icons.apple, color: AppColors.white),
                  label: const Text('Continuer avec Apple', style: TextStyle(color: AppColors.white)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: widget.onNavigateToSignUp,
                    child: const Text(
                      "Pas encore de compte ? S'inscrire",
                      style: TextStyle(color: AppColors.gold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.lightGray),
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
