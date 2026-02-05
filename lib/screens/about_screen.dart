import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF121212);
    const cardDark = Color(0xFF1E1E1E);
    const accentBlue = Color(0xFF2962FF);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tentang Developer', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // PROFILE
            const CircleAvatar(
              radius: 50,
              backgroundColor: cardDark,
              child: Icon(LucideIcons.user, size: 50, color: Colors.white), // Ganti foto nanti
            ),
            const SizedBox(height: 16),
            Text('Ahmad Wildan Abdillah', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Fullstack Developer & Founder Vixel', style: GoogleFonts.poppins(color: accentBlue, fontWeight: FontWeight.w500)),
            
            const SizedBox(height: 32),

            // SKRIPSI INFO CARD
            _buildInfoCard(
              title: 'Tentang SanadFlow',
              desc: 'Platform agregator video dakwah berbasis kurasi sanad untuk meminimalisir fragmentasi informasi di era digital. Dikembangkan sebagai Tugas Akhir KPI UINSA.',
              icon: LucideIcons.bookOpen,
              color: Colors.greenAccent,
            ),

            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Portfolio Lainnya', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),

            // VIXEL CARD
            _buildPortfolioCard(
              title: 'Vixel Creative',
              subtitle: 'Digital Creative Agency',
              desc: 'Agensi digital yang melayani pembuatan website, branding, dan sistem informasi. (vixelcreative.my.id)',
              color: Colors.blueAccent,
              onTap: () => _launchUrl('https://vixelcreative.my.id'),
            ),

            const SizedBox(height: 12),

            // PUSKESWAN CARD
            _buildPortfolioCard(
              title: 'Puskeswan App',
              subtitle: 'Gov-Tech Solution',
              desc: 'Aplikasi manajemen pelayanan kesehatan hewan Dinas Pertanian Trenggalek. (Flutter + Supabase).',
              color: Colors.orangeAccent,
              onTap: () {},
            ),

            const SizedBox(height: 40),
            Text('Versi 1.0.0 (Alpha Build)', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String desc, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[400], height: 1.5, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard({required String title, required String subtitle, required String desc, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 4, height: 50,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(LucideIcons.arrowRight, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}