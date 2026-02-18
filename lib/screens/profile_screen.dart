import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';
import 'package:sanadflow_mobile/screens/about_screen.dart';
import 'package:sanadflow_mobile/screens/dashboard_screen.dart';
import 'package:sanadflow_mobile/screens/edit_profile_screen.dart'; // Pastikan file ini ada
import 'package:sanadflow_mobile/screens/settings_screen.dart';     // Pastikan file ini ada

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

  // --- 1. AMBIL DATA PROFIL ---
  Future<void> _fetchProfile() async {
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIC NAMA ROLE (TEXT) ---
  String _getRoleBadge(String? role, String? email) {
    if (email == null) return 'JAMAAH';
    
    // Normalisasi biar huruf kecil semua (biar gak error kalau ada kapital)
    final e = email.toLowerCase(); 

    // A. FOUNDER (Spesifik Email Pribadi)
    if (e == 'amd.wildanabdillah@gmail.com') {
      return 'FOUNDER VIXEL';
    }

    // B. DEVELOPER (Email Kantor/Tim)
    if (e.contains('vixel')) {
      return 'LEAD DEVELOPER';
    }
    
    // C. ROLE DARI DATABASE
    switch (role) {
      case 'admin': return 'ADMINISTRATOR';
      case 'contributor': return 'KONTRIBUTOR';
      case 'ustadz': return 'PENCERAMAH';
      default: return 'JAMAAH';
    }
  }

  // --- 3. LOGIC WARNA BADGE (COLOR) ---
  Color _getBadgeColor(String badgeText) {
    switch (badgeText) {
      case 'FOUNDER VIXEL': return const Color(0xFFFFD700); // Emas
      case 'LEAD DEVELOPER': return const Color(0xFF00E5FF); // Cyan Terang
      case 'ADMINISTRATOR': return Colors.redAccent;        // Merah
      case 'KONTRIBUTOR': return Colors.greenAccent;        // Hijau
      case 'PENCERAMAH': return Colors.purpleAccent;        // Ungu
      default: return const Color(0xFF2962FF);              // Biru (Default)
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
    final email = user?.email; // Bisa null kalau guest
    final metaName = user?.userMetadata?['full_name'];
    final metaAvatar = user?.userMetadata?['avatar_url'];
    
    // Data Tampilan
    final fullName = _profileData?['full_name'] ?? metaName ?? 'Hamba Allah';
    final role = _profileData?['role'] ?? 'viewer';

    // Hitung Badge & Warna di sini
    final badgeText = _getRoleBadge(role, email);
    final badgeColor = _getBadgeColor(badgeText);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("Profil Saya", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // FOTO PROFIL
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2), // Border ngikutin warna role
                  image: DecorationImage(
                    image: metaAvatar != null 
                      ? NetworkImage(metaAvatar) 
                      : const NetworkImage("https://via.placeholder.com/150"),
                    fit: BoxFit.cover
                  )
                ),
                child: metaAvatar == null ? const Icon(LucideIcons.user, size: 50, color: Colors.grey) : null,
              ),
              
              const SizedBox(height: 16),
              
              // NAMA LENGKAP
              Text(fullName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 8),
              
              // BADGE ROLE (KEREN & DINAMIS)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15), // Transparan dikit
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor)
                ),
                child: Text(
                  badgeText, 
                  style: GoogleFonts.poppins(
                    color: badgeColor, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.2
                  )
                ),
              ),
              
              const SizedBox(height: 30),
              
              // CARD DASHBOARD (Khusus Admin/Kontributor/Founder)
              if (role == 'admin' || role == 'contributor' || badgeText == 'FOUNDER VIXEL')
                _buildMenuCard(
                  icon: LucideIcons.layoutDashboard,
                  title: "Masuk Dashboard",
                  subtitle: "Kelola konten kajian & data",
                  color: const Color(0xFF1E1E1E),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))
                )
              else 
                _buildMenuCard(
                  icon: LucideIcons.userPlus,
                  title: "Daftar Jadi Kontributor",
                  subtitle: "Bagikan kajian bermanfaat",
                  color: const Color(0xFF1E1E1E),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))
                ),
              
              const SizedBox(height: 20),

              // MENU OPSI
              _buildMenuItem(LucideIcons.edit3, "Edit Profil", () async {
                 final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                 if (result == true) _fetchProfile(); // Refresh kalau ada perubahan nama
              }),
              
              _buildMenuItem(LucideIcons.settings, "Pengaturan", () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              }),
              
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

  Widget _buildMenuCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.greenAccent)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)), Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12))])),
          const Icon(LucideIcons.chevronRight, color: Colors.grey)
        ]),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: isDestructive ? Colors.redAccent : Colors.white)),
      title: Text(title, style: GoogleFonts.poppins(color: isDestructive ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
    );
  }
}