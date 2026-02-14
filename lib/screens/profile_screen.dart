import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';
import 'package:sanadflow_mobile/screens/dashboard_screen.dart'; // Buat Admin/Contributor
import 'package:sanadflow_mobile/screens/about_screen.dart';
import 'package:sanadflow_mobile/screens/edit_profile_screen.dart';
import 'package:sanadflow_mobile/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = Supabase.instance.client.auth.currentUser;

  // LOGIC SAKTI: CUSTOM TITLE (GIMMICK KEREN)
  String _getCustomTitle(String email, String role) {
    if (email.contains('wildan')) return 'Founder Vixel'; // Easter Egg 1
    if (email.contains('vixel')) return 'Core Developer'; // Easter Egg 2
    
    // Role Base Title
    if (role == 'admin') return 'Administrator';
    if (role == 'contributor') return 'Kontributor Dakwah';
    
    return 'Penuntut Ilmu'; // Default User
  }

  // LOGIC PENGAJUAN CONTRIBUTOR
  Future<void> _applyForContributor() async {
    // Tampilkan Dialog Konfirmasi
    showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Daftar Kontributor", style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          "Apakah Anda ingin bergabung membagikan konten dakwah? Akun Anda akan ditinjau oleh Admin.",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        actions: [
          TextButton(child: const Text("Batal"), onPressed: () => Navigator.pop(c)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
            child: const Text("Ajukan", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(c);
              try {
                await Supabase.instance.client.from('profiles').update({
                  'contributor_status': 'pending'
                }).eq('id', user!.id);
                setState(() {}); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengajuan dikirim! Tunggu acc Admin.")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengajukan.")));
              }
            },
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kalau user belum login (Tamu), tampilkan halaman login
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.lock, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Silakan Login Terlebih Dahulu", style: GoogleFonts.poppins(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text("Login Sekarang", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    // STREAM PROFILE DATA
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: Text('Profil Saya', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan Segera Hadir!")));
            },
          )
        ],
      ),
      
      body: StreamBuilder<Map<String, dynamic>>(
        stream: Supabase.instance.client
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', user!.id)
            .map((list) => list.isNotEmpty ? list.first : {}),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final profile = snapshot.data!;
          final role = profile['role'] ?? 'viewer';
          final status = profile['contributor_status'] ?? 'none';
          final customTitle = _getCustomTitle(user!.email ?? '', role); // <--- INI FITUR KERENNYA

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
            child: Column(
              children: [
                // 1. FOTO PROFIL
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2962FF), width: 2),
                    image: profile['avatar_url'] != null
                        ? DecorationImage(image: NetworkImage(profile['avatar_url']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: profile['avatar_url'] == null 
                      ? const Icon(LucideIcons.user, size: 40, color: Colors.white) 
                      : null,
                ),
                const SizedBox(height: 16),
                
                // 2. NAMA & TITLE KEREN
                Text(
                  profile['full_name'] ?? 'Pengguna',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2962FF).withOpacity(0.5))
                  ),
                  child: Text(
                    customTitle.toUpperCase(), // "FOUNDER VIXEL" / "PENUNTUT ILMU"
                    style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),

                const SizedBox(height: 40),

                // 3. ROLE MANAGEMENT CARD (SHOPEE STYLE)
                if (role == 'admin' || role == 'contributor') ...[
                  // KALO UDAH JADI ADMIN/CONTRIBUTOR -> TAMPILKAN TOMBOL DASHBOARD
                  _buildMenuCard(
                    title: "Dashboard Konten",
                    subtitle: "Kelola video kajian dan ustadz",
                    icon: LucideIcons.layoutDashboard,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
                  ),
                ] else if (status == 'pending') ...[
                  // KALO LAGI DIAJUIN
                  _buildMenuCard(
                    title: "Pengajuan Sedang Ditinjau",
                    subtitle: "Mohon tunggu persetujuan Admin",
                    icon: LucideIcons.clock,
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ] else ...[
                  // KALO MASIH VIEWER -> TOMBOL DAFTAR
                  _buildMenuCard(
                    title: "Daftar Jadi Kontributor",
                    subtitle: "Bagikan kajian bermanfaat untuk umat",
                    icon: LucideIcons.userPlus,
                    color: Colors.green,
                    onTap: _applyForContributor,
                  ),
                ],

                const SizedBox(height: 20),

                // 4. MENU UMUM
                _buildMenuItem("Edit Profil", LucideIcons.edit3, () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                }),
                _buildMenuItem("Pengaturan", LucideIcons.settings, () { // <--- TAMBAHIN INI
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
                _buildMenuItem("Tentang Aplikasi", LucideIcons.info, () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget Card Besar (Buat Dashboard/Daftar)
  Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // Widget Menu List Biasa
  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white, size: 20),
      ),
      title: Text(
        title, 
        style: GoogleFonts.poppins(
          color: isDestructive ? Colors.redAccent : Colors.white, 
          fontWeight: FontWeight.w500
        )
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}