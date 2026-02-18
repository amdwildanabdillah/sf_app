import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';
import 'package:sanadflow_mobile/screens/about_screen.dart';
import 'package:sanadflow_mobile/screens/dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // --- LOGIC AMBIL DATA (KEBAL ERROR) ---
  Future<void> _fetchProfile() async {
    if (user == null) return;

    try {
      // 1. Coba ambil dari Database
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false; // STOP LOADING SUKSES
        });
      }
    } catch (e) {
      debugPrint("Error profile: $e");
      // 2. Kalau Error, tetep STOP Loading (Biar gak kluwer-kluwer)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC JUDUL ROLE (CUSTOM) ---
  String _getRoleBadge(String? role, String? email) {
    // BACKDOOR FOUNDER (Biar keren)
    if (email != null && (email.contains('wildan') || email.contains('vixel'))) {
      return 'FOUNDER VIXEL';
    }
    
    // Normal Check
    switch (role) {
      case 'admin': return 'ADMINISTRATOR';
      case 'contributor': return 'KONTRIBUTOR';
      case 'ustadz': return 'DAI TERVERIFIKASI';
      default: return 'JAMAAH';
    }
  }

  // --- LOGIC LOGOUT ---
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data Cadangan (Kalau DB Gagal/Null)
    final email = user?.email ?? 'Tamu';
    final metaName = user?.userMetadata?['full_name'];
    final metaAvatar = user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];

    // Prioritas Data: Database > Google Auth > Default
    final fullName = _profileData?['full_name'] ?? metaName ?? 'Hamba Allah';
    final role = _profileData?['role'] ?? 'viewer';
    // const avatarPlaceholder = "https://ui-avatars.com/api/?background=random&name="; 

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("Profil Saya", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hapus tombol back (karena ini tab utama)
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile, // Tarik buat refresh
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- 1. FOTO PROFIL ---
              Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2962FF), width: 2),
                      image: DecorationImage(
                        image: metaAvatar != null 
                            ? NetworkImage(metaAvatar) 
                            : const NetworkImage("https://via.placeholder.com/150"), // Placeholder sementara
                        fit: BoxFit.cover
                      ),
                    ),
                    child: metaAvatar == null ? const Icon(LucideIcons.user, size: 50, color: Colors.grey) : null,
                  ),
                  if (_isLoading) 
                    const Positioned.fill(child: CircularProgressIndicator(color: Colors.white))
                ],
              ),
              
              const SizedBox(height: 16),
              
              // --- 2. NAMA & BADGE ---
              Text(fullName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2962FF))
                ),
                child: Text(
                  _getRoleBadge(role, email), 
                  style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. MENU NAVIGASI ---
              // KHUSUS: Menu Daftar Kontributor / Dashboard
              _buildMenuCard(
                icon: role == 'admin' || role == 'contributor' ? LucideIcons.layoutDashboard : LucideIcons.userPlus,
                title: role == 'admin' || role == 'contributor' ? "Masuk Dashboard" : "Daftar Jadi Kontributor",
                subtitle: role == 'admin' || role == 'contributor' ? "Kelola konten kajian" : "Bagikan kajian bermanfaat",
                color: const Color(0xFF1E1E1E),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                }
              ),

              const SizedBox(height: 20),

              // Menu Umum
              _buildMenuItem(LucideIcons.edit3, "Edit Profil", () {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Edit Profil segera hadir!")));
              }),
              _buildMenuItem(LucideIcons.settings, "Pengaturan", () {}),
              _buildMenuItem(LucideIcons.info, "Tentang Aplikasi", () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
              }),
              
              const SizedBox(height: 20),
              
              _buildMenuItem(LucideIcons.logOut, "Keluar", _signOut, isDestructive: true),
              
              const SizedBox(height: 40),
              Text("Versi 1.0.0 (Beta)", style: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET CARD BESAR (DASHBOARD/DAFTAR)
  Widget _buildMenuCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.greenAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey)
          ],
        ),
      ),
    );
  }

  // WIDGET MENU LIST BIASA
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: isDestructive ? Colors.redAccent : Colors.white),
      ),
      title: Text(title, style: GoogleFonts.poppins(color: isDestructive ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
    );
  }
}