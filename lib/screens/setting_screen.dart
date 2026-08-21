import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../repositories/lansia_repository.dart';

/// Screen pengaturan: informasi akun, kontak & target notifikasi
/// WhatsApp, dan tombol logout.
class SettingScreen extends StatefulWidget {
  final String lansiaId;

  const SettingScreen({super.key, required this.lansiaId});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _repo = LansiaRepository();
  final _formKey = GlobalKey<FormState>();
  final _noHpKeluargaController = TextEditingController();
  final _noHpLansiaController = TextEditingController();

  String _target = 'keluarga'; // 'keluarga' | 'lansia'
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    if (widget.lansiaId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final kontak = await _repo.getKontak(widget.lansiaId);
      _noHpKeluargaController.text = kontak.noHpKeluarga;
      _noHpLansiaController.text = kontak.noHpLansia ?? '';
      _target = kontak.notifikasiTarget;
    } catch (e) {
      _errorMessage = 'Gagal memuat data kontak: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    // Kalau target notifikasi "lansia" tapi nomor lansia kosong, cegah
    // supaya tidak tersimpan setting yang bikin notifikasi gagal terkirim.
    if (_target == 'lansia' && _noHpLansiaController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Isi No. HP Lansia dulu, atau pilih target "Keluarga".');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _repo.updateKontak(
        lansiaId: widget.lansiaId,
        noHpKeluarga: _noHpKeluargaController.text.trim(),
        noHpLansia: _noHpLansiaController.text.trim(),
        notifikasiTarget: _target,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan notifikasi berhasil disimpan.')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AuthService().keluar();
              // AuthGate otomatis redirect ke LoginScreen
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noHpKeluargaController.dispose();
    _noHpLansiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;
    final email = user?.email ?? '-';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Info Akun ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, size: 28, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun Anda',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Notifikasi WhatsApp ───────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chat_bubble_outline, color: AppColors.success, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Notifikasi WhatsApp',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dikirim otomatis setiap obat diambil atau gagal diverifikasi.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),

                        TextFormField(
                          controller: _noHpKeluargaController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. HP Keluarga',
                            prefixIcon: Icon(Icons.family_restroom_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'No. HP Keluarga wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _noHpLansiaController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. HP Lansia (opsional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                            helperText: 'Isi kalau lansia punya HP sendiri',
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Kirim notifikasi ke',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),

                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'keluarga',
                              label: Text('Keluarga'),
                              icon: Icon(Icons.family_restroom_outlined),
                            ),
                            ButtonSegment(
                              value: 'lansia',
                              label: Text('Lansia'),
                              icon: Icon(Icons.person_outline),
                            ),
                          ],
                          selected: {_target},
                          onSelectionChanged: (selected) {
                            setState(() => _target = selected.first);
                          },
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2DC),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _simpan,
                            icon: _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Simpan Pengaturan'),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
        const SizedBox(height: 16),

        // ── Informasi Aplikasi ────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: AppColors.muted, size: 20),
                ),
                title: Text(
                  'Versi Aplikasi',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.devices, color: AppColors.muted, size: 20),
                ),
                title: Text(
                  'Nama Perangkat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  'Dispenser Obat Pintar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Tombol Logout ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
        ),
      ],
    );
  }
}