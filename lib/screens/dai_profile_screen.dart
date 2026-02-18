import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';

class DaiProfileScreen extends StatefulWidget {
  final String daiId;
  final String daiName;
  final String? daiAvatar;

  const DaiProfileScreen({
    super.key, 
    required this.daiId, 
    required this.daiName,
    this.daiAvatar
  });

  @override
  State<DaiProfileScreen> createState() => _DaiProfileScreenState();
}

class _DaiProfileScreenState extends State<DaiProfileScreen> {
  Map<String, dynamic>? _daiData;
  List<Map<String, dynamic>> _kajianList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDaiDetails();
  }

  // AMBIL DATA LENGKAP DAI + KAJIANNYA
  Future<void> _fetchDaiDetails() async {
    try {
      // 1. Ambil Detail Profil (Bio, Sosmed)
      final daiResponse = await Supabase.instance.client
          .from('dais')
          .select()
          .eq('id', widget.daiId)
          .single();

      // 2. Ambil List Video Beliau
      final kajianResponse = await Supabase.instance.client
          .from('kajian_lengkap') // Ambil dari View biar lengkap
          .select()
          .eq('dai_id', widget.daiId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _daiData = daiResponse;
          _kajianList = List<Map<String, dynamic>>.from(kajianResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FUNGSI BUKA SOSMED
  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(widget.daiName, style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- 1. HEADER PROFIL ---
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: widget.daiAvatar != null ? NetworkImage(widget.daiAvatar!) : null,
                  child: widget.daiAvatar == null ? const Icon(LucideIcons.user, size: 40, color: Colors.white) : null,
                ),
                const SizedBox(height: 16),
                Text(widget.daiName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                
                // BIO SINGKAT
                if (_daiData?['bio'] != null)
                  Text(
                    _daiData!['bio'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                  ),

                const SizedBox(height: 20),

                // --- 2. ROW SOSMED (YOUTUBE, IG, TIKTOK, FANBASE) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(LucideIcons.youtube, Colors.red, _daiData?['youtube_channel']),
                    _socialButton(LucideIcons.instagram, Colors.purpleAccent, _daiData?['instagram_url']),
                    _socialButton(Icons.tiktok, Colors.white, _daiData?['tiktok_url']), // Icon TikTok pake material icons
                    _socialButton(LucideIcons.users, Colors.blue, _daiData?['fanbase_url']), // Fanbase
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.white10),
                const SizedBox(height: 20),

                // --- 3. LIST KAJIAN ---
                Align(alignment: Alignment.centerLeft, child: Text("Kajian Terbaru", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),

                _kajianList.isEmpty
                    ? Padding(padding: const EdgeInsets.all(20), child: Text("Belum ada kajian.", style: GoogleFonts.poppins(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kajianList.length,
                        itemBuilder: (context, index) {
                          final item = _kajianList[index];
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: item['thumbnail_url'] != null 
                                  ? Image.network(item['thumbnail_url'], width: 60, height: 60, fit: BoxFit.cover)
                                  : Container(width: 60, height: 60, color: Colors.black),
                              ),
                              title: Text(item['title'] ?? 'Tanpa Judul', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                              subtitle: Text("${item['views'] ?? 0} views", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)),
                              onTap: () {
                                // Buka Video Detail lagi
                                Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
                                   'title': item['title'],
                                   'author': widget.daiName, // Pakai nama dari parent biar aman
                                   'video_url': item['video_url'],
                                   'img': item['thumbnail_url'],
                                   'desc': item['description'],
                                   'dai_id': widget.daiId, // Penting buat save
                                   'id': item['id'], // Penting buat save
                                })));
                              },
                            ),
                          );
                        },
                      )
              ],
            ),
          ),
    );
  }

  Widget _socialButton(IconData icon, Color color, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink(); // Sembunyikan kalau link kosong
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        onPressed: () => _launchUrl(url),
        icon: Icon(icon, color: color, size: 28),
        style: IconButton.styleFrom(backgroundColor: Colors.white10),
      ),
    );
  }
}