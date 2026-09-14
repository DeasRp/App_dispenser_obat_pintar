import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/device_provider.dart';
import '../repositories/keluarga_repository.dart';
import '../repositories/lansia_repository.dart';
import 'hubungkan_lansia_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String lansiaId;

  const ProfileScreen({super.key, required this.lansiaId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _muatData();
    if (mounted && context.read<DeviceProvider>().isKeluarga) {
      _refreshRelation();
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
      _showMessage('No. HP Keluarga wajib diisi.');
      return false;
    }
    if (perluLansia && noHpLansia.isEmpty) {
      _showMessage('No. HP Lansia wajib diisi.');
      return false;
    }

    setState(() => _isSaving = true);
    try {
      await _repo.updateKontak(
        lansiaId: widget.lansiaId,
        noHpKeluarga: noHpKeluarga,
        noHpLansia: noHpLansia,
        notifikasiTarget: target,
      );
      if (mounted) {
        setState(() => _target = target);
        _showMessage(
          target == 'keduanya'
              ? 'Notifikasi akan dikirim ke Keluarga dan Lansia.'
              : 'Pengaturan notifikasi berhasil disimpan.',
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

  Future<void> _showNotificationSettings() async {
    String targetDialog = _target;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.canvas,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHeader(
                    icon: Icons.chat_bubble_outline,
                    title: 'Notifikasi WhatsApp',
                    subtitle: 'Atur nomor dan penerima notifikasi dispenser.',
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
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'keluarga', label: Text('Keluarga')),
                        ButtonSegment(value: 'lansia', label: Text('Lansia')),
                        ButtonSegment(value: 'keduanya', label: Text('Keduanya')),
                      ],
                      selected: {targetDialog},
                      onSelectionChanged: (selected) {
                        setSheetState(() => targetDialog = selected.first);
                      },
                    ),
                  ),
                  if (targetDialog == 'keduanya') ...[
                    const SizedBox(height: 10),
                    _infoBanner(
                      Icons.info_outline,
                      'Notifikasi akan dikirim ke nomor Keluarga dan Lansia.',
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
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
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
      backgroundColor: AppColors.canvas,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: FutureBuilder<LansiaTerhubungModel?>(
          future: _relationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 220,
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
                _sheetHeader(
                  icon: Icons.family_restroom_outlined,
                  title: 'Hubungan Lansia',
                  subtitle: 'Kelola akun Lansia yang sedang dipantau.',
                ),
                const SizedBox(height: 20),
                if (lansia == null) ...[
                  _infoBanner(
                    Icons.link_off_outlined,
                    'Akun keluarga belum terhubung dengan akun Lansia.',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.10),
                          child: Text(
                            lansia.nama.isEmpty
                                ? 'L'
                                : lansia.nama.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lansia.email,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
      backgroundColor: AppColors.canvas,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHeader(
                icon: Icons.info_outline,
                title: 'Tentang ObatKu',
                subtitle: 'Informasi aplikasi dispenser obat pintar.',
              ),
              const SizedBox(height: 18),
              const Text(
                'ObatKu membantu mengatur jadwal, memantau stok, dan melihat '
                'riwayat pengambilan obat melalui dispenser pintar.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 14),
              _infoBanner(Icons.verified_outlined, 'ObatKu • Versi 1.0.0'),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBanner(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.body,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHero(DeviceProvider deviceProvider) {
    final profile = deviceProvider.profile;
    final email = AuthService().currentUser?.email ?? '-';
    final nama = (profile?.nama ?? '').trim().isEmpty
        ? 'Pengguna ObatKu'
        : profile!.nama;
    final roleLabel = deviceProvider.isKeluarga ? 'Keluarga' : 'Lansia';
    final initial = nama.isEmpty ? 'O' : nama.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFEEF1),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  icon: deviceProvider.isMqttConnected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  label: 'Dispenser',
                  value: deviceProvider.isMqttConnected ? 'Online' : 'Offline',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroStat(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifikasi',
                  value: _targetLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFFFEEF1),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _targetLabel {
    switch (_target) {
      case 'lansia':
        return 'Lansia';
      case 'keduanya':
        return 'Keduanya';
      default:
        return 'Keluarga';
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 21, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          height: 1.35,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.mutedSoft),
      onTap: onTap,
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.only(left: 70, right: 16),
        child: Divider(height: 1),
      );

  @override
  void dispose() {
    _noHpKeluargaController.dispose();
    _noHpLansiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _profileHero(deviceProvider),
            const SizedBox(height: 22),
            _sectionTitle(
              'Akun & komunikasi',
              'Kelola informasi akun dan penerima notifikasi.',
            ),
            _menuCard(
              children: [
                _menuTile(
                  icon: Icons.account_circle_outlined,
                  iconColor: const Color(0xFF6C63FF),
                  title: 'Informasi Profil',
                  subtitle: 'Nama, email, dan peran akun ditampilkan di bagian atas.',
                  onTap: null,
                ),
                _divider(),
                _menuTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: AppColors.success,
                  title: 'Notifikasi WhatsApp',
                  subtitle: _isLoading
                      ? 'Memuat pengaturan...'
                      : 'Target saat ini: $_targetLabel',
                  onTap: _isLoading ? null : _showNotificationSettings,
                ),
              ],
            ),
            if (deviceProvider.isKeluarga) ...[
              const SizedBox(height: 22),
              _sectionTitle(
                'Koneksi keluarga',
                'Atur akun Lansia yang dipantau melalui ObatKu.',
              ),
              _menuCard(
                children: [
                  _menuTile(
                    icon: Icons.family_restroom_outlined,
                    iconColor: AppColors.primary,
                    title: 'Hubungan Lansia',
                    subtitle: 'Lihat, ganti, atau putuskan akun Lansia yang terhubung.',
                    onTap: () => _showRelationSettings(deviceProvider),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _sectionTitle(
              'Aplikasi',
              'Informasi aplikasi dan pengelolaan sesi akun.',
            ),
            _menuCard(
              children: [
                _menuTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.warning,
                  title: 'Tentang ObatKu',
                  subtitle: 'Informasi sistem dan versi aplikasi.',
                  onTap: _showAbout,
                ),
                _divider(),
                _menuTile(
                  icon: Icons.logout,
                  iconColor: AppColors.error,
                  title: 'Keluar dari Akun',
                  subtitle: 'Akhiri sesi akun pada perangkat ini.',
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'ObatKu • v1.0.0',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
