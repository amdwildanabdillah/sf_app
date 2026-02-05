import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:sanadflow_mobile/screens/login_screen.dart'; // <--- HAPUS INI
import 'package:sanadflow_mobile/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfigurasi Supabase (Punya kamu yang tadi)
  await Supabase.initialize(
    url: 'https://jpaagyecfxhzjpzstgsi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwYWFneWVjZnhoempwenN0Z3NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgyMjM2NDQsImV4cCI6MjA1MzgwMzY0NH0.R5ccI6IkpXVCJ9.ey-DUMMY-KEY', 
  );

  runApp(const SanadFlowApp());
}

class SanadFlowApp extends StatelessWidget {
  const SanadFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SanadFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        // Vixel Style: Hitam Pekat, Aksen Putih & Biru Elektrik
        scaffoldBackgroundColor: const Color(0xFF121212), 
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF2962FF), // Biru Vixel
        ),
        
        // Setup Google Fonts Global (Poppins)
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
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
      // home: const LoginScreen(), 
      home: const HomeScreen(), 
    );
  }
}