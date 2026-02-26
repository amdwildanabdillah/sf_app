import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:sanadflow_mobile/screens/dai_profile_screen.dart'; 
import 'package:sanadflow_mobile/widgets/universal_video_player.dart'; // <--- PANGGIL OTAK PINTAR

class VideoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;
  const VideoDetailScreen({super.key, required this.videoData});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  bool _isSaved = false; 
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfSaved(); 
  }

  Future<void> _checkIfSaved() async {
    if (user == null || widget.videoData['id'] == null) return;
    try {
      final res = await Supabase.instance.client.from('saved_kajian').select().eq('user_id', user!.id).eq('kajian_id', widget.videoData['id']).maybeSingle();
      if (mounted) setState(() => _isSaved = res != null);
    } catch (e) {}
  }

  Future<void> _toggleSave() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login dulu untuk menyimpan!")));
      return;
    }
    final videoId = widget.videoData['id']; 
    if (videoId == null) return;
    setState(() => _isSaved = !_isSaved); 
    try {
      if (_isSaved) {
        await Supabase.instance.client.from('saved_kajian').insert({'user_id': user!.id, 'kajian_id': videoId});
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Disimpan ke koleksi")));
      } else {
        await Supabase.instance.client.from('saved_kajian').delete().eq('user_id', user!.id).eq('kajian_id', videoId);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus dari koleksi")));
      }
    } catch (e) {
      setState(() => _isSaved = !_isSaved);
    }
  }

  void _shareVideo() {
    Share.share("Tonton kajian ini: ${widget.videoData['title']}\n${widget.videoData['video_url']}\n\nvia SanadFlow App");
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.videoData['title'] ?? 'Tanpa Judul';
    final description = widget.videoData['desc'] ?? widget.videoData['description'] ?? 'Tidak ada deskripsi.';
    final author = widget.videoData['author'] ?? widget.videoData['dai_name'] ?? 'Ustadz';
    final category = widget.videoData['category'] ?? 'Umum';
    final sourceName = widget.videoData['source_account_name'];
    final daiId = widget.videoData['dai_id'];
    final daiAvatar = widget.videoData['dai_avatar'];
    final isVerified = widget.videoData['is_verified'] == true; 
    final videoUrl = widget.videoData['video_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // --- PLAYER SAKTI ---
            Stack(
              children: [
                  SafeArea(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: UniversalVideoPlayer(
                        videoUrl: videoUrl,
                        autoPlay: true, // <--- INI KUNCINYA
                      ),
                  ),
                ),
                Positioned(
                  top: 10, left: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF2962FF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(category.toUpperCase(), style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        if (sourceName != null && sourceName.toString().isNotEmpty) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                Icon(LucideIcons.userCheck, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text("Clipper: $sourceName", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 10)),
                              ],
                            )
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _actionButton(LucideIcons.thumbsUp, "Like", () {}), 
                        _actionButton(LucideIcons.share2, "Bagikan", _shareVideo), 
                        _actionButton(_isSaved ? LucideIcons.bookmarkMinus : LucideIcons.bookmarkPlus, _isSaved ? "Disimpan" : "Simpan", _toggleSave, isActive: _isSaved),
                        _actionButton(LucideIcons.flag, "Lapor", () {}), 
                      ],
                    ),
                    const SizedBox(height: 24), const Divider(color: Colors.white10), const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        if (daiId != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DaiProfileScreen(daiId: daiId, daiName: author, daiAvatar: daiAvatar)));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data profil ustadz belum lengkap")));
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24, backgroundColor: Colors.grey[800],
                            backgroundImage: daiAvatar != null && daiAvatar.toString().isNotEmpty ? NetworkImage(daiAvatar) : null,
                            child: daiAvatar == null || daiAvatar.toString().isEmpty ? const Icon(LucideIcons.user, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text(author, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    if (isVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, color: Colors.blueAccent, size: 16)],
                                  ],
                                ),
                                Text("Klik untuk lihat profil", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Colors.grey)
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), const Divider(color: Colors.white10), const SizedBox(height: 24),
                    Text("Deskripsi Kajian", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Text(description, style: GoogleFonts.poppins(color: Colors.grey[300], height: 1.5)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: isActive ? const Color(0xFF2962FF) : Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(color: isActive ? const Color(0xFF2962FF) : Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}