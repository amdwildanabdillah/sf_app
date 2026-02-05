import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sanadflow_mobile/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // --- LOGIC LOGIN GOOGLE NATIVE ---
  Future<void> _googleSignIn() async {
    // Cek koneksi internet dulu (visual check aja)
    setState(() => _isLoading = true);

    try {
      // 1. Web Client ID (Wajib buat Supabase, ambil dari Google Cloud)
      // Pastikan ini ID yang tipe "Web application"
      const webClientId = '965575022029-5404g6jidgr3ron6m8iqaphqe307vshe.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      // Proses Pilih Akun (Native Pop-up)
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // Batal
      }

      // Ambil Token
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'Gagal mendapatkan token akses Google.';
      }

      // 2. Kirim ke Supabase
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken ?? '',
        accessToken: accessToken,
      );

      // 3. Masuk Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      
    } on AuthException catch (e) {
      if (mounted) _showError('Login Gagal: ${e.message}');
    } catch (e) {
      // Handle Error 7 & 10 disini biar jelas
      String msg = e.toString();
      if (msg.contains('ApiException: 7')) {
        msg = "Koneksi Bermasalah. Cek internet HP kamu.";
      } else if (msg.contains('ApiException: 10')) {
        msg = "Settingan SHA-1 Salah. Cek Google Cloud.";
      }
      if (mounted) _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Background Gelap Vixel
      body: SafeArea(
        child: Center( // <-- BIAR TENGAH (Ala Puskeswan)
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // <-- RATA TENGAH
              children: [
                // LOGO ICON
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(LucideIcons.waves, size: 50, color: Colors.white),
                ),
                
                const SizedBox(height: 24),
                
                // JUDUL
                Text(
                  'SanadFlow.',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agregator Kajian Islam\nBerbasis Sanad Keilmuan',
                  textAlign: TextAlign.center, // <-- TEKS RATA TENGAH
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                ),
                
                const SizedBox(height: 60),

                // TOMBOL LOGIN GOOGLE
                _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFF2962FF))
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _googleSignIn,
                        // Link PNG Wikimedia yang Stabil
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          height: 24,
                        ),
                        label: Text(
                          'Masuk dengan Google',
                          style: GoogleFonts.poppins(
                            color: Colors.black, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                
                const SizedBox(height: 24),
                
                // TOMBOL TAMU
                TextButton(
                  onPressed: () {
                     Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  child: Text('Masuk Tanpa Login (Tamu)', style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),

                const SizedBox(height: 40),
                Text('v1.0.0 Alpha • Vixel Creative', style: GoogleFonts.poppins(color: Colors.white12, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}