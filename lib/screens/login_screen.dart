import 'dart:io'; 
import 'package:flutter/foundation.dart'; 
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- LOGIN GOOGLE (SUPORT WEB & HP) ---
  Future<void> _googleSignIn() async {
    // 1. CEK KALAU INI WEB
    if (kIsWeb) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://sanadflow-mobile.vercel.app/', // Pastikan ada slash di akhir
        );
        // Kalau Web, dia bakal redirect keluar, jadi gak perlu navigasi manual di sini
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Web Gagal: $e')));
        setState(() => _isLoading = false);
      }
      return;
    }

    // 2. CEK KALAU WINDOWS/LINUX (Gak Support Google Sign In)
    if (Platform.isWindows || Platform.isLinux) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Di PC pake Email di bawah aja ya Mas! 👇")));
      return;
    }

    // 3. CARA LOGIN UNTUK HP (ANDROID/IOS)
    setState(() => _isLoading = true);
    try {
      // Ganti Client ID ini dengan 'Web Client ID' dari Google Cloud Console
      // (Bukan Android Client ID ya, tapi yang Web)
      const webClientId = '965575022029-5404g6jidgr3ron6m8iqaphqe307vshe.apps.googleusercontent.com'; 
      
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; 
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) throw 'Token Google tidak ditemukan.';

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken ?? '',
        accessToken: accessToken,
      );

      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login HP Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIN EMAIL ---
  Future<void> _emailSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi email & password dulu")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email/Password Salah'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // --- 1. LOGO BUKU + PLAY (DESAIN VIXEL) ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon Buku Putih
                    Icon(
                      LucideIcons.bookOpen, 
                      size: 90, 
                      color: Colors.white.withOpacity(0.9),
                    ),
                    // Icon Play Biru (Tumpuk di bawah buku)
                    Positioned(
                      bottom: 15, 
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212), // Background hitam biar ikonnya kepotong rapi
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
                        ),
                        padding: const EdgeInsets.all(2), // Border tipis
                        child: const Icon(
                          Icons.play_circle_fill, 
                          size: 35, 
                          color: Color(0xFF2962FF), // Biru Vixel
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // --- 2. JUDUL & TAGLINE ---
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
                  'Validitas Sanad, Kualitas Umat', 
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400], 
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 60),

                // --- 3. TOMBOL GOOGLE ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _googleSignIn,
                    icon: const Icon(LucideIcons.chrome, color: Colors.black),
                    label: Text('Lanjutkan dengan Google', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),

                const SizedBox(height: 30),
                Row(children: [
                  Expanded(child: Divider(color: Colors.white24)), 
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("LOGIN ALTERNATIF", style: TextStyle(color: Colors.white24, fontSize: 10))), 
                  Expanded(child: Divider(color: Colors.white24))
                ]),
                const SizedBox(height: 20),

                // --- 4. FORM EMAIL (WINDOWS DEV) ---
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecor("Email", LucideIcons.mail),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecor("Password", LucideIcons.lock),
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _emailSignIn,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Masuk Akun", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen())),
                  child: Text("Masuk Tanpa Login (Tamu)", style: GoogleFonts.poppins(color: Colors.grey)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true, fillColor: const Color(0xFF1E1E1E),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
    );
  }
}