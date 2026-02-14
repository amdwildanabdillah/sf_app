import 'dart:ui'; // WAJIB ADA BUAT BLUR
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true, // Biar header kaca ngambang di atas konten
      
      // --- HEADER GLASSMORPHISM (SAMA KAYAK HOME) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hilangkan tombol back default
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: Text('SANADFLOW', style: GoogleFonts.poppins(fontWeight: FontWeight.w300, letterSpacing: 4, fontSize: 20, color: Colors.white)),
      ),

      body: SafeArea(
        top: false, // Matikan safe area atas biar header kaca gak kepotong
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 0), // Top 110 biar turun di bawah Header
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // SEMUA RATA TENGAH BIAR SIMETRIS
            children: [
              // JUDUL HALAMAN (THIN & CENTER)
              Text("Jelajah Kajian", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400)), // w400 = Regular (Gak Bold)
              
              const SizedBox(height: 20),
              
              // SEARCH FIELD
              TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: "Cari judul, ustadz, atau topik...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                  suffixIcon: _query.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: (){
                        _searchController.clear();
                        setState(() => _query = "");
                      }) 
                    : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), // Rounded Search biar match sama Nav
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
              ),
              
              const SizedBox(height: 24),

              // KONTEN UTAMA
              Expanded(
                child: _query.isEmpty 
                  ? _buildCategoryGrid() 
                  : _buildSearchResults(), 
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('categories').stream(primaryKey: ['id']).order('name'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;

        if (categories.isEmpty) {
          return Center(child: Text("Belum ada kategori", style: GoogleFonts.poppins(color: Colors.grey)));
        }

        return Column(
          children: [
            Text("Telusuri Topik", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)), // Subtitle kecil
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.text = cat['name'];
                          _query = cat['name'];
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          cat['name'], 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w400) // Thin juga
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('kajian').select().ilike('title', '%$_query%'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.searchX, size: 60, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text("Tidak ditemukan", style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        final results = snapshot.data!;

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = results[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tileColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item['thumbnail_url'] ?? '',
                  width: 60, height: 60, fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(color: Colors.grey[800]),
                ),
              ),
              title: Text(item['title'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(item['category'] ?? '-', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
                   'title': item['title'],
                   'author': 'Dai',
                   'video_url': item['video_url'],
                   'img': item['thumbnail_url'],
                   'desc': item['description']
                 })));
              },
            );
          },
        );
      },
    );
  }
}