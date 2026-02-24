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
  List<Map<String, dynamic>> _sanadList = []; // <--- Data dari dai_sanads
  
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Kajian, 1: Sanad Keilmuan

  @override
  void initState() {
    super.initState();
    _fetchDaiDetails();
  }

  // --- AMBIL DATA DARI SUPABASE (dais & dai_sanads) ---
  Future<void> _fetchDaiDetails() async {
    try {
      // 1. Ambil Data Profil Ustadz (Bio, Avatar, Sosmed)
      final daiResponse = await Supabase.instance.client
          .from('dais')
          .select()
          .eq('id', widget.daiId)
          .single();

      // 2. Ambil List Kajian Beliau
      final kajianResponse = await Supabase.instance.client
          .from('kajian_lengkap') 
          .select()
          .eq('dai_id', widget.daiId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      // 3. Ambil List Pohon Sanad (Guru/Instansi)
      final sanadResponse = await Supabase.instance.client
          .from('dai_sanads')
          .select()
          .eq('dai_id', widget.daiId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _daiData = daiResponse;
          _kajianList = List<Map<String, dynamic>>.from(kajianResponse);
          _sanadList = List<Map<String, dynamic>>.from(sanadResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // BUKA LINK EXTERNAL (SOSMED / WEB PESANTREN)
  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // FOTO PRIORITAS DARI DATABASE 'dais'
    final String? displayAvatar = _daiData?['avatar_url'] ?? widget.daiAvatar;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(widget.daiName, style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- 1. AVATAR & NAMA ---
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty 
                      ? NetworkImage(displayAvatar) 
                      : null,
                  child: displayAvatar == null || displayAvatar.isEmpty 
                      ? const Icon(LucideIcons.user, size: 40, color: Colors.white) 
                      : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.daiName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (_daiData?['is_verified'] == true) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blueAccent, size: 24),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                if (_daiData?['bio'] != null)
                  Text(_daiData!['bio'], textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),

                const SizedBox(height: 20),

                // --- 2. TOMBOL SOSMED ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(LucideIcons.youtube, Colors.red, _daiData?['youtube_channel']),
                    _socialButton(LucideIcons.instagram, Colors.purpleAccent, _daiData?['instagram_url']),
                    _socialButton(Icons.tiktok, Colors.white, _daiData?['tiktok_url']),
                  ],
                ),

                const SizedBox(height: 30),

                // --- 3. NAVIGASI TAB ---
                _buildTabNavigation(),
                const SizedBox(height: 16),

                // --- 4. TAMPILAN KAJIAN ATAU SANAD ---
                _selectedTab == 0 ? _buildKajianView(displayAvatar) : _buildSanadView(),
              ],
            ),
          ),
    );
  }

  Widget _socialButton(IconData icon, Color color, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink(); 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        onPressed: () => _launchUrl(url),
        icon: Icon(icon, color: color, size: 28),
        style: IconButton.styleFrom(backgroundColor: Colors.white10),
      ),
    );
  }

  Widget _buildTabNavigation() {
    if (_sanadList.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft, 
        child: Text("Kajian Terbaru", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
      );
    }

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 2))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedTab == 0 ? Colors.blueAccent : Colors.transparent, width: 3))),
                child: Center(child: Text("Kajian", style: GoogleFonts.poppins(color: _selectedTab == 0 ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedTab == 1 ? Colors.blueAccent : Colors.transparent, width: 3))),
                child: Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.network, size: 16, color: _selectedTab == 1 ? Colors.white : Colors.grey),
                    const SizedBox(width: 8),
                    Text("Sanad Keilmuan", style: GoogleFonts.poppins(color: _selectedTab == 1 ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKajianView(String? displayAvatar) {
    if (_kajianList.isEmpty) return Padding(padding: const EdgeInsets.all(20), child: Text("Belum ada kajian.", style: GoogleFonts.poppins(color: Colors.grey)));
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: _kajianList.length,
      itemBuilder: (context, index) {
        final item = _kajianList[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: item['thumbnail_url'] != null ? Image.network(item['thumbnail_url'], width: 60, height: 60, fit: BoxFit.cover) : Container(width: 60, height: 60, color: Colors.black),
            ),
            title: Text(item['title'] ?? 'Tanpa Judul', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            subtitle: Text("${item['views'] ?? 0} views", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
                 'title': item['title'], 'author': widget.daiName, 'video_url': item['video_url'],
                 'img': item['thumbnail_url'], 'desc': item['description'], 'dai_id': widget.daiId, 
                 'id': item['id'], 'dai_avatar': displayAvatar, 'is_verified': item['is_verified'], 
                 'source_account_name': item['source_account_name'],
              })));
            },
          ),
        );
      },
    );
  }

  Widget _buildSanadView() {
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: _sanadList.length,
      itemBuilder: (context, index) {
        final item = _sanadList[index];
        IconData catIcon = LucideIcons.bookOpen;
        String cat = (item['kategori'] ?? '').toString().toLowerCase();
        if (cat.contains('pesantren') || cat.contains('pondok')) catIcon = LucideIcons.building;
        else if (cat.contains('universitas') || cat.contains('kampus') || cat.contains('kuliah')) catIcon = LucideIcons.graduationCap;
        else if (cat.contains('talaqqi') || cat.contains('guru')) catIcon = LucideIcons.users;

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(catIcon, color: Colors.blueAccent),
            ),
            title: Text(item['nama_instansi_guru'] ?? '-', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (item['periode'] != null && item['periode'].toString().isNotEmpty)
                  Text(item['periode'], style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w500)),
                if (item['deskripsi'] != null && item['deskripsi'].toString().isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(item['deskripsi'], style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12))),
              ],
            ),
            trailing: (item['website_url'] != null && item['website_url'].toString().isNotEmpty)
                ? IconButton(
                    icon: const Icon(LucideIcons.externalLink, color: Colors.grey, size: 20),
                    onPressed: () => _launchUrl(item['website_url']),
                    tooltip: "Kunjungi Website Resmi",
                  )
                : null,
          ),
        );
      },
    );
  }
}