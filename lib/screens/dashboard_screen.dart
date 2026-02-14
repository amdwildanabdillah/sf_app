import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- INI YANG TADI KELUPAAN!
import 'package:sanadflow_mobile/screens/admin_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // STREAM: Ambil semua kajian realtime
  final _kajianStream = Supabase.instance.client
      .from('kajian')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  // LOGIC: HAPUS VIDEO
  Future<void> _deleteKajian(String id) async {
    try {
      await Supabase.instance.client.from('kajian').delete().eq('id', id);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video dihapus")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
    }
  }

  // LOGIC: JADIIN FEATURED (KAJIAN PILIHAN)
  Future<void> _toggleFeatured(String id, bool currentValue) async {
    try {
      await Supabase.instance.client.from('kajian').update({
        'is_featured': !currentValue 
      }).eq('id', id);
    } catch (e) {
      debugPrint("Gagal update featured: $e");
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
          onPressed: () => Navigator.pop(context)
        ),
        title: Text("Manajemen Konten", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      
      // TOMBOL TAMBAH (Lari ke Form Upload)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2962FF),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text("Upload Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
        },
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _kajianStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.folderOpen, color: Colors.white24, size: 60),
                  const SizedBox(height: 16),
                  Text("Belum ada konten", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = data[index];
              final isFeatured = item['is_featured'] == true;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: isFeatured ? Border.all(color: const Color(0xFF2962FF), width: 1) : null 
                ),
                child: Row(
                  children: [
                    // THUMBNAIL
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item['thumbnail_url'] ?? '',
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorWidget: (c,u,e) => Container(color: Colors.grey[800], child: const Icon(Icons.error)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? 'Tanpa Judul',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            item['category'] ?? '-',
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // ACTIONS
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(isFeatured ? Icons.star : Icons.star_border, color: isFeatured ? Colors.amber : Colors.grey),
                          onPressed: () => _toggleFeatured(item['id'], isFeatured),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            showDialog(context: context, builder: (c) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: const Text("Hapus Video?", style: TextStyle(color: Colors.white)),
                              actions: [
                                TextButton(child: const Text("Batal"), onPressed: () => Navigator.pop(c)),
                                TextButton(child: const Text("HAPUS", style: TextStyle(color: Colors.red)), onPressed: () {
                                  Navigator.pop(c);
                                  _deleteKajian(item['id']);
                                }),
                              ],
                            ));
                          },
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}