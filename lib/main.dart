import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart'; 
import 'package:sanadflow_mobile/screens/home_screen.dart'; // <--- INI WAJIB ADA
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfigurasi Supabase (Punya kamu yang tadi)
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
    return MaterialApp(
      title: 'SanadFlow',
      debugShowCheckedModeBanner: false, // Hapus label DEBUG miring itu
      theme: ThemeData.dark().copyWith(
        // Vixel Style: Hitam Pekat, Aksen Putih & Biru Elektrik
        scaffoldBackgroundColor: const Color(0xFF121212), // Dark Grey (Enak di mata)
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF2962FF), // Biru Vixel
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto', 
            fontWeight: FontWeight.bold, 
            fontSize: 20,
            letterSpacing: 1.2
          ),
        ),
      ),
      // Arahkan awal buka ke Login Screen dulu
      // home: const LoginScreen(), // <-- Matikan (kasih garis miring 2)
      home: const HomeScreen(),     // <-- Ganti jadi ini (Langsung masuk)
    );
  }
}