import 'package:supabase_flutter/supabase_flutter.dart';

/// Inisialisasi koneksi Supabase.
/// Panggil SupabaseService.init() sekali di main() sebelum runApp().
///
/// Cara dapatkan url & anonKey:
/// Dashboard Supabase -> Project Settings -> API
class SupabaseService {
  static const String supabaseUrl = 'https://wevsfvdxlyjrrfezjcmp.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndldnNmdmR4bHlqcnJmZXpqY21wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1NDA3ODgsImV4cCI6MjEwMTExNjc4OH0.3pZhhrfYN6-S98VWg4N07MPuudO_hxAMhk3mLg5zung';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
