import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sanadflow_mobile/widgets/universal_video_player.dart';

class VideoDetailScreen extends StatefulWidget {
  final Map<String, String> videoData;

  const VideoDetailScreen({super.key, required this.videoData});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final Color bgDark = const Color(0xFF121212);
  final Color cardDark = const Color(0xFF1E1E1E);
  final Color accentBlue = const Color(0xFF2962FF);

  bool _isSaved = false;

  Future<void> _launchSourceURL() async {
    final String urlString = widget.videoData['source_url'] ?? 'https://instagram.com';
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka link: $urlString"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _shareVideo() async {
    // --- PERBAIKAN: Gunakan share_plus dengan benar ---
    final String text = 'Tonton kajian "${widget.videoData['title']}" di SanadFlow! \n${widget.videoData['source_url']}';
    await Share.share(text); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                UniversalVideoPlayer(
                  videoUrl: widget.videoData['video_url']!,
                ),
                Positioned(
                  top: 10, left: 10,
                  child: CircleAvatar(
                    // --- PERBAIKAN: withValues ---
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
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
                    Text(
                      widget.videoData['title'] ?? 'Judul Tidak Tersedia',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${widget.videoData['views'] ?? '2.4K'} Views', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 4, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.videoData['date'] ?? '2 Hari lalu', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: _isSaved ? Icons.bookmark : Icons.bookmark_border, 
                          label: 'Simpan', 
                          color: _isSaved ? accentBlue : Colors.white,
                          onTap: () {
                            setState(() => _isSaved = !_isSaved);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_isSaved ? "Disimpan ke Daftar Saya" : "Dihapus dari Daftar"), duration: const Duration(seconds: 1))
                            );
                          }
                        ),
                        _buildActionButton(icon: LucideIcons.share2, label: 'Bagikan', onTap: _shareVideo),
                        _buildActionButton(icon: LucideIcons.externalLink, label: 'Sumber', onTap: _launchSourceURL),
                        _buildActionButton(icon: LucideIcons.flag, label: 'Lapor', onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20, backgroundColor: cardDark,
                          backgroundImage: NetworkImage(widget.videoData['author_img'] ?? 'https://via.placeholder.com/150'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.videoData['author'] ?? 'Ustadz', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Verified Creator', style: GoogleFonts.poppins(color: Colors.blueGrey, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          child: Text('Follow', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Kajian tentang pentingnya menjaga sanad keilmuan di era digital agar tidak tersesat dalam informasi yang salah. Video ini menjelaskan metode validasi hadits dan pendapat ulama.",
                      style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 30),
                    Text("Kajian Serupa", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        separatorBuilder: (context, index) => const SizedBox(width: 12), // <-- PERBAIKAN
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(8), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1542816417-0983c9c9ad53?q=80&w=200'), fit: BoxFit.cover)),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}