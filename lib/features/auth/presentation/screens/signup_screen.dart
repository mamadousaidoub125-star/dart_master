import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Écran d'inscription : création de compte par email + pseudo public.
class SignUpScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final void Function(AppUser user) onSignUpSuccess;
  final VoidCallback onNavigateToLogin;

  const SignUpScreen({
    super.key,
    required this.authRepository,
    required this.onSignUpSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
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
      final user = await widget.authRepository.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );
      widget.onSignUpSuccess(user);
    } catch (e) {
      setState(() => _errorMessage = "Impossible de créer le compte. Réessayez.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(backgroundColor: AppColors.midnightBlue, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Créer un compte',
                  style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rejoins la compétition et grimpe au classement mondial',
                  style: TextStyle(color: AppColors.lightGray, fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _displayNameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _inputDecoration('Pseudo public'),
                  validator: (value) =>
                      (value == null || value.trim().length < 3) ? '3 caractères minimum' : null,
                ),
                const SizedBox(height: 16),
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
                      : const Text("S'inscrire"),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: widget.onNavigateToLogin,
                    child: const Text(
                      'Déjà un compte ? Se connecter',
                      style: TextStyle(color: AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "En t'inscrivant, tu acceptes notre politique de confidentialité.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.lightGray, fontSize: 12),
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
