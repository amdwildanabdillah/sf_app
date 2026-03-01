import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Buat load .env

// Import halaman-halaman
import 'package:sanadflow_mobile/screens/login_screen.dart';
import 'package:sanadflow_mobile/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. BUKA BRANKAS .ENV ---
  // Pastikan file .env dibaca sebelum Supabase diinisialisasi
  await dotenv.load(fileName: ".env");

  // --- 2. KONFIGURASI SUPABASE (VERSI AMAN) ---
  // Tarik data URL dan Anon Key dari dalam brankas .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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