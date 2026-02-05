import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/about_screen.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Ambil Data User Saat Ini
  final user = Supabase.instance.client.auth.currentUser;

  Future<void> _signOut() async {
    // Proses Logout
    await Supabase.instance.client.auth.signOut();
    
    if (mounted) {
      // Lempar balik ke Login Screen & Hapus semua history navigasi
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // LOGIC: Kalau user null (Tamu), pakai data dummy
    final String fullName = user?.userMetadata?['full_name'] ?? 'Pengguna Tamu';
    final String email = user?.email ?? 'Belum login';
    final String? photoUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // FOTO PROFIL DINAMIS
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2962FF), width: 2),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20)]
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: photoUrl != null 
                    ? NetworkImage(photoUrl) 
                    : null,
                  child: photoUrl == null 
                    ? const Icon(LucideIcons.user, size: 40, color: Colors.white) 
                    : null,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // NAMA & EMAIL DINAMIS
              Text(
                fullName, 
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
              ),
              Text(
                email, 
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey)
              ),
              
              const SizedBox(height: 30),
              
              // Menu Options
              _buildMenuOption(context, LucideIcons.user, "Edit Profil"),
              _buildMenuOption(context, LucideIcons.settings, "Pengaturan"),
              _buildMenuOption(context, LucideIcons.info, "Tentang Aplikasi", onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
              }),
              
              const SizedBox(height: 20),
              
              // TOMBOL KELUAR
              _buildMenuOption(
                context, 
                LucideIcons.logOut, 
                "Keluar", 
                color: Colors.redAccent,
                onTap: _signOut // Panggil fungsi logout
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, IconData icon, String title, {Color color = Colors.white, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}