import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // Jangan lupa package ini biar fontnya cakep

// Import halaman-halaman
import 'package:sanadflow_mobile/screens/login_screen.dart';
import 'package:sanadflow_mobile/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfigurasi Supabase (Sesuai punya kamu)
  await Supabase.initialize(
    url: 'https://jpaagyecfxhzjpzstgsi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwYWFneWVjZnhoempwenN0Z3NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMjgxNDQsImV4cCI6MjA4NTcwNDE0NH0.Vh9lDS64jmb5ZMnyflpl6HRe6XxNfnA6JtJTwIUM-sI',
  );

  runApp(const SanadFlowApp());
}

class SanadFlowApp extends StatelessWidget {
  const SanadFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- LOGIC SATPAM (PENJAGA PINTU) ---
    // Cek apakah ada data user yang tersimpan di HP?
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return MaterialApp(
      title: 'SanadFlow',
      debugShowCheckedModeBanner: false,
      
      // Tema Vixel (Dark Mode + Poppins)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF2962FF),
        ),
        // Kita balikin ke Poppins biar konsisten sama desain Vixel
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),

      // --- PENENTUAN HALAMAN AWAL ---
      // Kalau isLoggedIn = TRUE (Ada sesi) -> Masuk HomeScreen
      // Kalau isLoggedIn = FALSE (Gak ada) -> Masuk LoginScreen
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}