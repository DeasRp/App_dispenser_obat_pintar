import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dispenser_obat_pintar/providers/device_provider.dart';
import 'package:dispenser_obat_pintar/screens/auth_gate.dart';
import 'package:dispenser_obat_pintar/core/services/supabase_service.dart';
import 'package:dispenser_obat_pintar/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => DeviceProvider()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dispenser Obat Pintar',
      // Gunakan tema Airbnb-inspired dari AppTheme — tanpa dark mode
      // (sesuai DESIGN.md: "Airbnb does not have a dark mode on the public web")
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
