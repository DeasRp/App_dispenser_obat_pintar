import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../repositories/keluarga_repository.dart';

class HubungkanLansiaScreen extends StatefulWidget {
  final Future<void> Function() onTerhubung;

  const HubungkanLansiaScreen({
    super.key,
    required this.onTerhubung,
  });

  @override
  State<HubungkanLansiaScreen> createState() => _HubungkanLansiaScreenState();
}

class _HubungkanLansiaScreenState extends State<HubungkanLansiaScreen> {
  final _repo = KeluargaRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _hubungkan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repo.hubungkanDenganEmailLansia(_emailController.text);
      await widget.onTerhubung();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil terhubung dengan Lansia.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubungkan Lansia'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.family_restroom,
                      size: 72,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hubungkan akun Keluarga dengan Lansia',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Masukkan email yang digunakan oleh akun Lansia di Remindora.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(
                        labelText: 'Email Lansia',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'contoh@email.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email Lansia wajib diisi';
                        if (!email.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_isLoading) _hubungkan();
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2DC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _hubungkan,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(_isLoading ? 'Menghubungkan...' : 'Hubungkan'),
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
