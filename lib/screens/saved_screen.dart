import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _savedStream = Supabase.instance.client
      .from('saved_kajian')
      .stream(primaryKey: ['id'])
      .eq('user_id', Supabase.instance.client.auth.currentUser?.id ?? '')
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,

      // --- HEADER GLASSMORPHISM ---
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
        title: Text('SANADFLOW', style: GoogleFonts.poppins(fontWeight: FontWeight.w300, letterSpacing: 4, fontSize: 20, color: Colors.white)),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _savedStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(LucideIcons.bookmark, size: 60, color: Colors.grey[800]), 
                  // Ganti icon bookmark jadi title aja biar bersih sesuai request
                  Text(
                    "Daftar Saya", 
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400)
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada video disimpan",
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 110, 20, 20), // Top 110 biar turun
            children: [
              Center(
                child: Text("Daftar Saya", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400))
              ),
              const SizedBox(height: 20),
              
              ...data.map((savedItem) {
                return _buildSavedItem(savedItem['kajian_id']);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSavedItem(String kajianId) {
    return FutureBuilder(
      future: Supabase.instance.client.from('kajian').select().eq('id', kajianId).single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final item = snapshot.data as Map<String, dynamic>;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
             'title': item['title'],
             'author': 'Dai',
             'video_url': item['video_url'],
             'img': item['thumbnail_url'],
             'desc': item['description']
          }))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item['thumbnail_url'] ?? '',
                    width: 100, height: 70, fit: BoxFit.cover,
                    errorWidget: (c,u,e) => Container(color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'], maxLines: 2, overflow: TextOverflow.ellipsis, 
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(item['category'] ?? 'Umum', 
                        style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.bookmarkMinus, color: Colors.grey, size: 20),
                  onPressed: () async {
                    await Supabase.instance.client.from('saved_kajian').delete()
                      .eq('kajian_id', kajianId)
                      .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}