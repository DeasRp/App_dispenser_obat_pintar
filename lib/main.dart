import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dispenser_obat_pintar/providers/device_provider.dart';
import 'package:dispenser_obat_pintar/screens/auth_gate.dart';
import 'package:dispenser_obat_pintar/core/services/supabase_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Automatically switch between light and dark
      home: const AuthGate(),
    );
  }
}
