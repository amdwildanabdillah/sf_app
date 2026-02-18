import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  // LOGIC PENCARIAN SAKTI
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // KITA CARI DI VIEW 'kajian_lengkap' (Bukan tabel kajian biasa)
      // Syntax .or() biar bisa cari di Judul ATAU Nama Dai ATAU Kategori
      final response = await Supabase.instance.client
          .from('kajian_lengkap')
          .select()
          .or('title.ilike.%$query%, dai_name.ilike.%$query%, category.ilike.%$query%')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error searching: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER & SEARCH BAR
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("Jelajah Kajian", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) {
                      // Debounce sederhana (tunggu user selesai ngetik dikit)
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (val == _searchController.text) {
                          _performSearch(val);
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari judul, ustadz, atau topik...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          }) 
                        : null,
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),

            // HASIL PENCARIAN
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
                : _searchResults.isEmpty 
                  ? (_isSearching 
                      ? _buildEmptyState() // Kalau nyari tapi gak ketemu
                      : _buildCategoryGrid()) // Kalau belum nyari (Tampilin Kategori)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['thumbnail_url'] != null
                                ? Image.network(item['thumbnail_url'], width: 60, height: 60, fit: BoxFit.cover)
                                : Container(width: 60, height: 60, color: Colors.black),
                            ),
                            title: Text(item['title'] ?? 'Tanpa Judul', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(item['dai_name'] ?? 'Ustadz', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
                                   'title': item['title'],
                                   'author': item['dai_name'],
                                   'video_url': item['video_url'],
                                   'img': item['thumbnail_url'],
                                   'desc': item['description'],
                                   'dai_id': item['dai_id'],
                                   'id': item['id'],
                                   'dai_avatar': item['dai_avatar'], // Penting buat profil
                              })));
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.searchX, size: 60, color: Colors.grey),
        const SizedBox(height: 16),
        Text("Tidak ditemukan", style: GoogleFonts.poppins(color: Colors.grey)),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = ['Fiqih', 'Aqidah', 'Sejarah', 'Muamalah', 'Tazkiyatun Nafs', 'Parenting'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text("Telusuri Topik", style: GoogleFonts.poppins(color: Colors.grey)),
        ),
        Wrap(
          spacing: 12, runSpacing: 12,
          alignment: WrapAlignment.center,
          children: categories.map((cat) => ActionChip(
            label: Text(cat),
            labelStyle: GoogleFonts.poppins(color: Colors.white),
            backgroundColor: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: () {
              _searchController.text = cat;
              _performSearch(cat);
            },
          )).toList(),
        ),
      ],
    );
  }
}