import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/device_provider.dart';
import '../repositories/keluarga_repository.dart';
import '../repositories/lansia_repository.dart';
import 'hubungkan_lansia_screen.dart';

class SettingScreen extends StatefulWidget {
  final String lansiaId;

  const SettingScreen({super.key, required this.lansiaId});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _repo = LansiaRepository();
  final _keluargaRepo = KeluargaRepository();
  final _formKey = GlobalKey<FormState>();
  final _noHpKeluargaController = TextEditingController();
  final _noHpLansiaController = TextEditingController();

  String _target = 'keluarga';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isManagingRelation = false;
  String? _errorMessage;
  Future<LansiaTerhubungModel?>? _relationFuture;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    if (widget.lansiaId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
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

    if (_target == 'lansia' && _noHpLansiaController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Isi No. HP Lansia dulu, atau pilih target "Keluarga".';
      });
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
          const SnackBar(
            content: Text('Pengaturan notifikasi berhasil disimpan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refreshRelation() {
    setState(() {
      _relationFuture = _keluargaRepo.getLansiaTerhubung();
    });
  }

  Future<void> _bukaPairing(DeviceProvider deviceProvider) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HubungkanLansiaScreen(
          onTerhubung: () async {
            await deviceProvider.refreshLansiaConnection();
            _refreshRelation();
          },
        ),
      ),
    );
  }

  Future<void> _putuskanHubungan(
    DeviceProvider deviceProvider,
    LansiaTerhubungModel lansia,
  ) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Putuskan Hubungan?'),
        content: Text(
          'Akun keluarga tidak akan lagi memantau ${lansia.nama}. '
          'Jadwal dan data Lansia tidak akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isManagingRelation = true);
    try {
      await _keluargaRepo.putuskanHubungan(lansia.lansiaId);
      await deviceProvider.refreshLansiaConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hubungan dengan Lansia diputuskan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutuskan hubungan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isManagingRelation = false);
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
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
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
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildRelationCard(
    BuildContext context,
    DeviceProvider deviceProvider,
  ) {
    final theme = Theme.of(context);
    _relationFuture ??= _keluargaRepo.getLansiaTerhubung();

    return _cardContainer(
      child: FutureBuilder<LansiaTerhubungModel?>(
        future: _relationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hubungan Keluarga ↔ Lansia',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat hubungan: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _refreshRelation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            );
          }

          final lansia = snapshot.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.family_restroom,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hubungan Keluarga ↔ Lansia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          lansia == null ? 'Belum terhubung' : 'Terhubung aktif',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: lansia == null
                                ? AppColors.muted
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (lansia == null) ...[
                const Text(
                  'Hubungkan akun keluarga dengan akun Lansia menggunakan email akun Lansia.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _bukaPairing(deviceProvider),
                    icon: const Icon(Icons.link),
                    label: const Text('Hubungkan Lansia'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceStrong,
                      child: Text(
                        lansia.nama.isEmpty
                            ? 'L'
                            : lansia.nama.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lansia.nama,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lansia.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Aktif',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isManagingRelation
                            ? null
                            : () => _bukaPairing(deviceProvider),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Ganti Lansia'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: _isManagingRelation
                            ? null
                            : () => _putuskanHubungan(
                                  deviceProvider,
                                  lansia,
                                ),
                        icon: const Icon(Icons.link_off),
                        label: const Text('Putuskan'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
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
    final deviceProvider = context.watch<DeviceProvider>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _cardContainer(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 28,
                  color: AppColors.primary,
                ),
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
                    const SizedBox(height: 2),
                    Text(
                      deviceProvider.isKeluarga ? 'Keluarga' : 'Lansia',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (deviceProvider.isKeluarga) ...[
          const SizedBox(height: 16),
          _buildRelationCard(context, deviceProvider),
        ],
        const SizedBox(height: 16),
        _cardContainer(
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
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: AppColors.success,
                              size: 20,
                            ),
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
                        'Atur nomor penerima notifikasi dari dispenser.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
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
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
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
        _cardContainer(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('Versi Aplikasi'),
                trailing: const Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices),
                title: const Text('Nama Perangkat'),
                trailing: const Text('Dispenser Obat Pintar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar dari Akun'),
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }
}
