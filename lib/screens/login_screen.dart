import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  
  // Controller buat Login Email (Windows Friendly)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // LOGIN GOOGLE (Mungkin error di Windows tanpa config khusus)
  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // Logic Google Sign In (Skip dulu kalau di Windows)
      // await Supabase.instance.client.auth.signInWithOAuth(...)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Login belum disetup buat Windows, pake Email dulu mas!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // LOGIN EMAIL (SOLUSI WINDOWS)
  Future<void> _emailSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi email & password dulu")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
         if(mounted) {
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
         }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Gagal. Cek Email/Pass.")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF2962FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.waves, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text("SANADFLOW", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(height: 8),
              Text("Masuk untuk melanjutkan", style: GoogleFonts.poppins(color: Colors.grey)),
              
              const SizedBox(height: 40),

              // TOMBOL GOOGLE (Gak jalan di Windows tapi biarin buat UI)
              _buildGoogleBtn(),

              const SizedBox(height: 30),
              
              // DIVIDER
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white24)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("DEV LOGIN (WINDOWS)", style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10))),
                  const Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              
              const SizedBox(height: 20),

              // FORM EMAIL (BUAT WINDOWS)
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

              // TOMBOL LOGIN EMAIL
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _emailSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("Masuk dengan Email", style: GoogleFonts.poppins(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleBtn() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _googleSignIn,
        icon: const Icon(LucideIcons.chrome, color: Colors.black), 
        label: Text("Lanjutkan dengan Google", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}