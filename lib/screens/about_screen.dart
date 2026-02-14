import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tentang Developer",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 1. FOTO GAGAH & TAMPAN
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2962FF), width: 2), 
                image: const DecorationImage(
                  // Pastikan nama file sesuai aset kamu
                  image: AssetImage('assets/images/wildan.jpg'), 
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2962FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 2. NAMA & TITLE
            Text(
              "Ahmad Wildan Abdillah",
              style: GoogleFonts.poppins(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Fullstack Developer & Founder Vixel",
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: const Color(0xFF2962FF), 
                fontWeight: FontWeight.w500
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 3. TENTANG SANADFLOW (Card Elegan)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.quote, color: Colors.white54, size: 24),
                  const SizedBox(height: 12),
                  Text(
                    "Tentang SanadFlow",
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Platform agregator video dakwah berbasis kurasi sanad untuk meminimalisir fragmentasi informasi di era digital. Dikembangkan sebagai Tugas Akhir KPI UINSA dengan pendekatan 'Zero Noise'.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      color: Colors.grey[400], 
                      height: 1.6
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 4. CONNECT SECTION (STYLE VIXEL)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(width: 4, height: 24, color: const Color(0xFF2962FF)), // Garis Aksen Biru
                  const SizedBox(width: 12),
                  Text(
                    "Connect with Me",
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GRID TOMBOL SOSMED (RATA KIRI & MONOKROM)
            GridView.count(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, // 2 Kolom
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.0, // Dibuat lebih gepeng (Wide) biar mirip Vixel
              children: [
                _socialButton("Instagram", LucideIcons.instagram, "https://instagram.com/idan_abdll"),
                _socialButton("LinkedIn", LucideIcons.linkedin, "https://linkedin.com/in/amdwildanabdillah-vixel"),
                _socialButton("GitHub", LucideIcons.github, "https://github.com/amdwildanabdillah"),
                _socialButton("Email", LucideIcons.mail, "mailto:vixelcreative.id@gmail.com"),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // TOMBOL WEBSITE UTAMA (Outline Style biar beda)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _launchURL("https://www.vixelcreative.my.id"),
                icon: const Icon(LucideIcons.globe, size: 20),
                label: Text(
                  "Visit Vixel Creative Website",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF2962FF)), // Border Biru
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            
            // COPYRIGHT
            Text(
              "© 2026 Vixel Creative. Surabaya, Indonesia.",
              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET TOMBOL SOSMED CUSTOM (Vixel Style: Rata Kiri & Clean)
  Widget _socialButton(String label, IconData icon, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), // Padding Kiri-Kanan
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Warna Card Gelap
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10), // Border Tipis
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, // <--- KUNCI KERAPIAN (RATA KIRI)
            children: [
              Icon(icon, color: Colors.white70, size: 18), // Icon Putih/Abu dikit
              const SizedBox(width: 12),
              Expanded( // Biar teks gak nabrak kalau kepanjangan
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white, 
                    fontWeight: FontWeight.w500,
                    fontSize: 13
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}