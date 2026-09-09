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
  final _noHpKeluargaController = TextEditingController();
  final _noHpLansiaController = TextEditingController();

  static const _targetTersedia = {'keluarga', 'lansia', 'keduanya'};

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
      _target = _targetTersedia.contains(kontak.notifikasiTarget)
          ? kontak.notifikasiTarget
          : 'keluarga';
    } catch (e) {
      _errorMessage = 'Gagal memuat data kontak: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _simpanNotifikasi(String target) async {
    final noHpKeluarga = _noHpKeluargaController.text.trim();
    final noHpLansia = _noHpLansiaController.text.trim();
    final perluKeluarga = target == 'keluarga' || target == 'keduanya';
    final perluLansia = target == 'lansia' || target == 'keduanya';

    if (!_targetTersedia.contains(target)) {
      _showMessage('Target notifikasi tidak valid.');
      return false;
    }

    if (perluKeluarga && noHpKeluarga.isEmpty) {
      _showMessage(
        target == 'keduanya'
            ? 'No. HP Keluarga wajib diisi untuk target Keduanya.'
            : 'No. HP Keluarga wajib diisi.',
      );
      return false;
    }

    if (perluLansia && noHpLansia.isEmpty) {
      _showMessage(
        target == 'keduanya'
            ? 'No. HP Lansia wajib diisi untuk target Keduanya.'
            : 'No. HP Lansia wajib diisi untuk target Lansia.',
      );
      return false;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _repo.updateKontak(
        lansiaId: widget.lansiaId,
        noHpKeluarga: noHpKeluarga,
        noHpLansia: noHpLansia,
        notifikasiTarget: target,
      );
      _target = target;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              target == 'keduanya'
                  ? 'Notifikasi akan dikirim ke Keluarga dan Lansia.'
                  : 'Pengaturan notifikasi berhasil disimpan.',
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) _showMessage('Gagal menyimpan pengaturan: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      _refreshRelation();
      if (mounted) _showMessage('Hubungan dengan Lansia diputuskan.');
    } catch (e) {
      if (mounted) _showMessage('Gagal memutuskan hubungan: $e');
    } finally {
      if (mounted) setState(() => _isManagingRelation = false);
    }
  }

  Future<void> _showAccountInfo(
    BuildContext context,
    DeviceProvider deviceProvider,
  ) async {
    final profile = deviceProvider.profile;
    final email = AuthService().currentUser?.email ?? '-';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Akun',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _infoRow(Icons.person_outline, 'Nama', profile?.nama ?? '-'),
              const Divider(height: 24),
              _infoRow(Icons.email_outlined, 'Email', email),
              const Divider(height: 24),
              _infoRow(
                Icons.badge_outlined,
                'Role',
                deviceProvider.isKeluarga ? 'Keluarga' : 'Lansia',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showNotificationSettings() async {
    String targetDialog = _target;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              4,
              24,
              MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifikasi WhatsApp',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Atur nomor penerima notifikasi dari dispenser.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _noHpKeluargaController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP Keluarga',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noHpLansiaController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP Lansia',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kirim notifikasi ke',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'keluarga',
                          label: Text('Keluarga'),
                        ),
                        ButtonSegment(
                          value: 'lansia',
                          label: Text('Lansia'),
                        ),
                        ButtonSegment(
                          value: 'keduanya',
                          label: Text('Keduanya'),
                        ),
                      ],
                      selected: {targetDialog},
                      onSelectionChanged: (selected) {
                        setSheetState(() => targetDialog = selected.first);
                      },
                    ),
                  ),
                  if (targetDialog == 'keduanya') ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Notifikasi akan dikirim ke nomor Keluarga dan nomor Lansia.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              final berhasil =
                                  await _simpanNotifikasi(targetDialog);
                              if (berhasil && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Simpan Pengaturan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRelationSettings(DeviceProvider deviceProvider) async {
    _relationFuture ??= _keluargaRepo.getLansiaTerhubung();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: FutureBuilder<LansiaTerhubungModel?>(
          future: _relationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 180,
                child: Center(
                  child: Text('Gagal memuat hubungan: ${snapshot.error}'),
                ),
              );
            }

            final lansia = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hubungan Lansia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                if (lansia == null) ...[
                  const Text(
                    'Akun keluarga belum terhubung dengan akun Lansia.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _bukaPairing(deviceProvider);
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Hubungkan Lansia'),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          lansia.nama.isEmpty
                              ? 'L'
                              : lansia.nama.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              lansia.email,
                              style: const TextStyle(color: AppColors.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isManagingRelation
                              ? null
                              : () async {
                                  Navigator.pop(sheetContext);
                                  await _bukaPairing(deviceProvider);
                                },
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Ganti'),
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
                              : () async {
                                  Navigator.pop(sheetContext);
                                  await _putuskanHubungan(
                                    deviceProvider,
                                    lansia,
                                  );
                                },
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
      ),
    );
  }

  Future<void> _showAbout() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang ObatKu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 14),
              Text(
                'ObatKu membantu mengatur jadwal dan memantau pengambilan obat melalui dispenser pintar.',
              ),
              SizedBox(height: 12),
              Text(
                'Versi 1.0.0',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
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

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceStrong,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.muted),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
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
    final deviceProvider = context.watch<DeviceProvider>();
    final profile = deviceProvider.profile;
    final email = AuthService().currentUser?.email ?? '-';
    final nama = (profile?.nama ?? '').trim().isEmpty
        ? 'Pengguna ObatKu'
        : profile!.nama;
    final roleLabel = deviceProvider.isKeluarga ? 'Keluarga' : 'Lansia';
    final initial = nama.isEmpty ? 'O' : nama.substring(0, 1).toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const SizedBox(height: 6),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    deviceProvider.isKeluarga
                        ? Icons.family_restroom
                        : Icons.medication_outlined,
                    size: 14,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          nama,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 5),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              _menuTile(
                icon: Icons.person_outline,
                title: 'Informasi Akun',
                subtitle: 'Nama, email, dan role',
                onTap: () => _showAccountInfo(context, deviceProvider),
              ),
              _divider(),
              _menuTile(
                icon: Icons.chat_bubble_outline,
                title: 'Notifikasi WhatsApp',
                subtitle: _isLoading
                    ? 'Memuat pengaturan...'
                    : 'Nomor dan penerima notifikasi',
                onTap: _isLoading ? () {} : _showNotificationSettings,
              ),
              if (deviceProvider.isKeluarga) ...[
                _divider(),
                _menuTile(
                  icon: Icons.family_restroom_outlined,
                  title: 'Hubungan Lansia',
                  subtitle: 'Kelola akun Lansia yang dipantau',
                  onTap: () => _showRelationSettings(deviceProvider),
                ),
              ],
              _divider(),
              _menuTile(
                icon: Icons.info_outline,
                title: 'Tentang ObatKu',
                subtitle: 'Versi aplikasi dan informasi sistem',
                onTap: _showAbout,
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Keluar dari Akun',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () => _showLogoutDialog(context),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'ObatKu • v1.0.0',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
