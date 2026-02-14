import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Text("Pengaturan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader("Umum"),
          _switchTile("Notifikasi Kajian Baru", "Dapatkan info video terbaru", _notifEnabled, (val) {
            setState(() => _notifEnabled = val);
          }),
          
          const SizedBox(height: 24),
          _sectionHeader("Penyimpanan"),
          _actionTile("Bersihkan Cache", "Hapus file sampah (Thumbnail dll)", LucideIcons.trash2, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cache berhasil dibersihkan!")));
          }),

          const SizedBox(height: 24),
          _sectionHeader("Akun"),
          _actionTile("Hapus Akun", "Tindakan ini permanen", LucideIcons.alertTriangle, () {
             // Logic Hapus Akun (Bahaya, kasih dialog konfirmasi dulu)
          }, isDestructive: true),
          
          const SizedBox(height: 40),
          Center(
            child: Text("SanadFlow v1.0.0 (Alpha)", style: GoogleFonts.poppins(color: Colors.white10, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
            Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
          ]),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF2962FF))
        ],
      ),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white),
        title: Text(title, style: GoogleFonts.poppins(color: isDestructive ? Colors.red : Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
        trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
      ),
    );
  }
}