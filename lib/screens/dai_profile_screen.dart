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

  const DaiProfileScreen({super.key, required this.daiId, required this.daiName, this.daiAvatar});

  @override
  State<DaiProfileScreen> createState() => _DaiProfileScreenState();
}

class _DaiProfileScreenState extends State<DaiProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _daiData;
  List<dynamic> _kajianList = [];
  List<dynamic> _sanadList = [];
  List<dynamic> _fanbaseList = [];

  @override
  void initState() {
    super.initState();
    _fetchDaiDetails();
  }

  Future<void> _fetchDaiDetails() async {
    try {
      final supabase = Supabase.instance.client;

      final daiRes = await supabase.from('dais').select().eq('id', widget.daiId).single();
      final kajianRes = await supabase.from('kajian').select().eq('dai_id', widget.daiId).order('created_at', ascending: false);
      final sanadRes = await supabase.from('dai_sanads').select('*, sanad_gurus(*)').eq('dai_id', widget.daiId).order('created_at', ascending: true);
      final fanbaseRes = await supabase.from('dai_fanbases').select().eq('dai_id', widget.daiId);

      if (mounted) {
        setState(() {
          _daiData = daiRes;
          _kajianList = kajianRes;
          _sanadList = sanadRes;
          _fanbaseList = fanbaseRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load profil dai: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka link')));
    }
  }

  void _showFanbaseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Akun Fanbase & Kontributor", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Sumber konten tervalidasi.", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 16),
              if (_fanbaseList.isEmpty)
                Text("Belum ada data fanbase.", style: GoogleFonts.poppins(color: Colors.grey, fontStyle: FontStyle.italic))
              else
                ..._fanbaseList.map((f) {
                  IconData icon = LucideIcons.link;
                  if (f['platform'] == 'instagram') icon = LucideIcons.instagram;
                  if (f['platform'] == 'youtube') icon = LucideIcons.youtube;
                  if (f['platform'] == 'tiktok') icon = Icons.tiktok;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: Colors.white10, child: Icon(icon, color: Colors.white, size: 18)),
                    title: Text(f['nama_akun'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                    subtitle: Text(f['platform'], style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 11)),
                    trailing: const Icon(LucideIcons.externalLink, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.pop(context); 
                      _launchURL(f['url_akun']); 
                    },
                  );
                })
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(backgroundColor: const Color(0xFF121212), elevation: 0, leading: const BackButton(color: Colors.white), title: Text("Profil Penceramah", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16))),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF))),
      );
    }

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(backgroundColor: const Color(0xFF121212), elevation: 0, leading: const BackButton(color: Colors.white), title: Text("Profil Penceramah", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16))),
        
        // --- FOOTER (SOSMED AMAN DARI POLICE LINE) ---
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(color: Color(0xFF1A1A1A), border: Border(top: BorderSide(color: Colors.white10))),
          child: SafeArea(
            child: Row(
              children: [
                Text("Connect:", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                
                // SOSMED BISA DI-SCROLL KE SAMPING KALAU KEPENUHAN
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_daiData?['instagram_url'] != null) IconButton(icon: const Icon(LucideIcons.instagram, color: Colors.white, size: 22), onPressed: () => _launchURL(_daiData!['instagram_url'])),
                        if (_daiData?['youtube_channel'] != null) IconButton(icon: const Icon(LucideIcons.youtube, color: Colors.white, size: 22), onPressed: () => _launchURL(_daiData!['youtube_channel'])),
                        if (_daiData?['tiktok_url'] != null) IconButton(icon: const Icon(Icons.tiktok, color: Colors.white, size: 22), onPressed: () => _launchURL(_daiData!['tiktok_url'])),
                        if (_daiData?['instagram_url'] == null && _daiData?['youtube_channel'] == null && _daiData?['tiktok_url'] == null)
                           Text(" Belum ada sosmed.", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                  icon: const Icon(LucideIcons.users, size: 16), label: Text("Fanbase", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: _showFanbaseSheet,
                )
              ],
            ),
          ),
        ),

        body: Column(
          children: [
            // --- HEADER FIXED (NAMA AMAN DARI POLICE LINE) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45, backgroundColor: Colors.grey[800],
                          backgroundImage: _daiData?['avatar_url'] != null ? NetworkImage(_daiData!['avatar_url']) : null,
                          child: _daiData?['avatar_url'] == null ? const Icon(LucideIcons.user, size: 40, color: Colors.white) : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _daiData?['name'] ?? widget.daiName, 
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_daiData?['is_verified'] == true) ...[
                              const SizedBox(width: 6), const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Bio / Profil Singkat", style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(_daiData?['bio'] ?? 'Belum ada informasi bio.', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            TabBar(
              indicatorColor: const Color(0xFF2962FF), labelColor: const Color(0xFF2962FF), unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13), tabs: const [Tab(text: "KAJIAN"), Tab(text: "SANAD")],
            ),
            
            Expanded(
              child: TabBarView(
                children: [_buildKajianTab(), _buildSanadTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKajianTab() {
    if (_kajianList.isEmpty) return Center(child: Text("Belum ada video kajian.", style: GoogleFonts.poppins(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: _kajianList.length,
      itemBuilder: (context, index) {
        final video = _kajianList[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {...video, 'dai_name': _daiData?['name'], 'dai_avatar': _daiData?['avatar_url'], 'is_verified': _daiData?['is_verified']}))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)), child: Image.network(video['thumbnail_url'] ?? '', width: 120, height: 90, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 120, height: 90, color: Colors.grey[800]))),
                Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(video['title'] ?? 'Tanpa Judul', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Text(video['category'] ?? 'Umum', style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 10, fontWeight: FontWeight.w600))])))]
            ),
          ),
        );
      },
    );
  }

  Widget _buildSanadTab() {
    if (_sanadList.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.gitMerge, size: 50, color: Colors.grey[800]), const SizedBox(height: 16), Text("Data sanad belum ditambahkan.", style: GoogleFonts.poppins(color: Colors.grey))]));
    return ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _sanadList.length,
      itemBuilder: (context, index) {
        final item = _sanadList[index]; final gurus = item['sanad_gurus'] as List<dynamic>? ?? []; final isLast = index == _sanadList.length - 1;
        IconData catIcon = LucideIcons.bookOpen; String cat = (item['kategori'] ?? '').toString().toLowerCase();
        if (cat.contains('pesantren') || cat.contains('pondok')) catIcon = LucideIcons.building; else if (cat.contains('universitas') || cat.contains('kampus')) catIcon = LucideIcons.graduationCap; else if (cat.contains('keluarga') || cat.contains('orang tua')) catIcon = LucideIcons.users;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF2962FF).withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2962FF), width: 2)), child: Icon(catIcon, color: const Color(0xFF2962FF), size: 16)), if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFF2962FF).withOpacity(0.3), margin: const EdgeInsets.symmetric(vertical: 4)))]),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), iconColor: const Color(0xFF2962FF), collapsedIconColor: Colors.grey,
                      title: Text(item['nama_instansi_guru'] ?? '-', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: item['periode'] != null && item['periode'].toString().isNotEmpty ? Text(item['periode'], style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 11, fontWeight: FontWeight.w600)) : null,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: Colors.white10), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)), child: Text("Jalur: ${item['kategori'] ?? '-'}", style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(height: 16),
                              if (gurus.isEmpty) Text("Belum ada rincian guru dicatat.", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)) else ...[Text("Masyayikh / Guru Pembimbing:", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 8), ...gurus.map((g) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 4), child: Icon(LucideIcons.userCheck, size: 14, color: Colors.blueAccent)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(g['nama_guru'], style: GoogleFonts.poppins(color: Colors.grey[200], fontSize: 13, fontWeight: FontWeight.w500)), if (g['spesialisasi_kitab'] != null) Text("Kitab/Ilmu: ${g['spesialisasi_kitab']}", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11))]))])))],
                              if (item['website_url'] != null && item['website_url'].toString().isNotEmpty) ...[const SizedBox(height: 16), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _launchURL(item['website_url']), icon: const Icon(LucideIcons.externalLink, size: 14, color: Colors.blueAccent), label: Text("Kunjungi Web Tabayyun", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueAccent)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))))]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}