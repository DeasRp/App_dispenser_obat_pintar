import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.masuk(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigasi otomatis ditangani oleh AuthGate lewat authStateChanges,
      // tidak perlu Navigator.push manual di sini.
    } on AuthException catch (e) {
      setState(() => _errorMessage = _pesanErrorRamah(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan, silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _pesanErrorRamah(String pesanAsli) {
    if (pesanAsli.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (pesanAsli.contains('Email not confirmed')) {
      return 'Email belum diverifikasi, silakan cek inbox Anda.';
    }
    return pesanAsli;
  }

  Future<void> _lupaPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Isi email terlebih dahulu untuk reset password.');
      return;
    }
    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link reset password telah dikirim ke email Anda.')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mengirim email reset password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ─────────────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/logo1.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Headline ────────────────────────────────────────────
                  Text(
                    'Dispenser Obat Pintar',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Masuk untuk mengelola jadwal obat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Email Field ─────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Password Field ──────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.muted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      return null;
                    },
                  ),

                  // ── Lupa Password ───────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _lupaPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: const Text('Lupa password?'),
                    ),
                  ),

                  // ── Error message ───────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2DC),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),

                  // ── CTA Button ──────────────────────────────────────────
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Register Link ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun?',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        child: const Text('Daftar sekarang'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}