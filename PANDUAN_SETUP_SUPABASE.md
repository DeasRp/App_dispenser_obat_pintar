# Panduan Integrasi Supabase ke App Dispenser Obat Pintar

## 1. Buat project Supabase
1. Daftar di https://supabase.com, buat project baru
2. Buka **SQL Editor**, paste isi file `schema_supabase.sql`, klik **Run**
3. Buka **Project Settings -> API**, catat:
   - `Project URL`
   - `anon public key`

## 2. Tambah dependency di `pubspec.yaml`
Tambahkan di bagian `dependencies:` (sejajar dengan `mqtt_client`):

```yaml
dependencies:
  supabase_flutter: ^2.8.0
```

Lalu jalankan:
```
flutter pub get
```

## 3. Salin file-file berikut ke project Anda
- `core/services/supabase_service.dart`
- `models/jadwal_obat_model.dart`
- `repositories/jadwal_repository.dart`
- `screens/kelola_jadwal_screen.dart`

Isi `supabaseUrl` dan `supabaseAnonKey` di `supabase_service.dart` dengan nilai dari langkah 1.

## 4. Tambah topic baru di `core/constants/mqtt_config.dart`
File ini tidak ada di repo (kemungkinan di-gitignore karena berisi kredensial broker). Tambahkan baris berikut ke class `MqttConfig` yang sudah ada:

```dart
static const String topicCmdSyncJadwal = 'medicine/cmd/sync_jadwal';
```

## 5. Inisialisasi Supabase di `main.dart`
Tambahkan sebelum `runApp()`:

```dart
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const MyApp());
}
```

## 6. Buka screen kelola jadwal
Dari `dashboard_screen.dart`, tambahkan tombol/navigasi ke `KelolaJadwalScreen`:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => KelolaJadwalScreen(
      lansiaId: 'uuid-lansia-anda',
      mqttService: deviceProvider.mqttService, // sesuaikan cara akses mqttService di provider Anda
    ),
  ),
);
```

Catatan: `DeviceProvider` saat ini menyimpan `_mqttService` sebagai private. Tambahkan getter berikut di `device_provider.dart` supaya bisa diakses dari screen lain:

```dart
MqttService get mqttService => _mqttService;
```

## 7. Isi `LANSIA_ID` di firmware ESP32
Buka `dispenser_obat_pintar.ino`, cari baris:

```cpp
const char* LANSIA_ID = "isi-uuid-lansia-di-sini";
```

Ganti dengan UUID lansia yang dikembalikan saat insert data awal di `schema_supabase.sql` (lihat query `insert into lansia ... returning id;`).

## 8. Aktifkan autentikasi email + password

### a. Jalankan skema tambahan
Buka SQL Editor Supabase, jalankan isi `schema_auth_tambahan.sql`. Ini akan:
- Menambah kolom `user_id` di tabel `lansia`
- Mengganti RLS policy jadi berbasis akun yang login (`auth.uid()`)

### b. Ganti kredensial ESP32 ke Service Role Key
Karena RLS sekarang membatasi akses berdasarkan user yang login, ESP32 (yang tidak login sebagai user biasa) butuh **service role key**, bukan anon key lagi.

1. Buka **Project Settings -> API** di Supabase, salin **service_role key** (bagian "secret", bukan "anon public")
2. Buka `dispenser_obat_pintar.ino`, isi:
   ```cpp
   const char* SUPABASE_SERVICE_KEY = "isi-service-role-key-di-sini";
   ```

**Peringatan keamanan:** service role key ini melewati semua RLS — jangan pernah dipakai di kode Flutter/app, hanya aman ditaruh di firmware yang tidak mudah dibongkar orang (walau tetap ada risiko kalau ESP32 hilang/dicuri fisiknya, karena kode bisa di-dump). Untuk skripsi ini biasanya masih bisa diterima, tapi sebutkan sebagai catatan keterbatasan sistem di laporan Anda.

### c. Tambah file autentikasi ke project
Salin file-file berikut:
- `core/services/auth_service.dart`
- `screens/login_screen.dart`
- `screens/register_screen.dart`
- `screens/auth_gate.dart`

### d. Ubah `main.dart` supaya mulai dari AuthGate

```dart
import 'core/services/supabase_service.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dispenser Obat Pintar',
      home: const AuthGate(), // <- ganti dari DashboardScreen langsung ke AuthGate
    );
  }
}
```

### e. Tambah tombol logout di dashboard
Di `dashboard_screen.dart`, tambahkan tombol logout (misal di AppBar):

```dart
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await AuthService().keluar();
    // AuthGate otomatis pindah ke LoginScreen karena stream authStateChanges
  },
)
```

### f. Ambil `lansiaId` dari user yang sedang login
Dashboard perlu tahu `lansia_id` milik user yang login untuk query jadwal. Tambahkan helper ini (bisa taruh di `JadwalRepository` atau provider Anda):

```dart
Future<String> getLansiaIdSayaSaatIni() async {
  final userId = SupabaseService.client.auth.currentUser!.id;
  final response = await SupabaseService.client
      .from('lansia')
      .select('id')
      .eq('user_id', userId)
      .single();
  return response['id'] as String;
}
```

Panggil ini sekali saat dashboard dibuka, simpan hasilnya, lalu pakai untuk semua query jadwal/riwayat berikutnya (ganti parameter `lansiaId` yang tadinya hardcoded).

1. Keluarga buka app -> `KelolaJadwalScreen` -> tambah/edit jadwal -> tersimpan ke Supabase
2. App otomatis mengirim MQTT `medicine/cmd/sync_jadwal` -> ESP32 langsung fetch ulang jadwal dari Supabase
3. ESP32 tetap sinkron ulang otomatis tiap 30 menit sebagai jaga-jaga kalau notifikasi MQTT terlewat (misal ESP32 sempat offline)
4. Setiap proses dispense (berhasil maupun gagal verifikasi) tercatat sebagai baris baru di tabel `riwayat_konsumsi` -- bisa ditampilkan di app sebagai riwayat/history
