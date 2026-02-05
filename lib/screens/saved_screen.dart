import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Daftar Saya', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.bookmark, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada video disimpan', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}