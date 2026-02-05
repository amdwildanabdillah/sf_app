import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Jelajah Kajian', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: (){}, icon: const Icon(LucideIcons.search))],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.compass, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Cari Kajian Berdasarkan Topik', style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 20),
            // Nanti disini kita kasih Grid Kategori
            OutlinedButton(onPressed: (){}, child: const Text("Coming Soon"))
          ],
        ),
      ),
    );
  }
}