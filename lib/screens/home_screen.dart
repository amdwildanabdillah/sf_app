import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sanadflow_mobile/screens/about_screen.dart';
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';
import 'package:sanadflow_mobile/screens/explore_screen.dart';
import 'package:sanadflow_mobile/screens/saved_screen.dart';
import 'package:sanadflow_mobile/screens/profile_screen.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';
// IMPORT ADMIN SCREEN
import 'package:sanadflow_mobile/screens/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'Semua';

  final user = Supabase.instance.client.auth.currentUser;

  String? get _photoUrl {
    final metadata = user?.userMetadata;
    return metadata?['avatar_url'] ?? metadata?['picture'];
  }

  // STREAM: Ini "Pipa" yang nyedot data dari Supabase secara Realtime
  final _kajianStream = Supabase.instance.client
      .from('kajian')
      .stream(primaryKey: ['id'])
      .order('id', ascending: false); // Yang baru diupload muncul duluan

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF121212);
    const cardDark = Color(0xFF1E1E1E);
    const accentBlue = Color(0xFF2962FF);

    final List<Widget> pages = [
      _buildHomeContent(bgDark, accentBlue),
      const ExploreScreen(),
      const SavedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: _currentIndex == 0,
      appBar: _currentIndex == 0 ? _buildHomeAppBar(cardDark: cardDark) : null,
      drawer: _currentIndex == 0 ? _buildDrawer(bgDark, accentBlue) : null,
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(bgDark, accentBlue),
    );
  }

  // --- DRAWER DENGAN MENU ADMIN ---
  Widget _buildDrawer(Color bg, Color accent) {
    final String fullName = user?.userMetadata?['full_name'] ?? 'Tamu';
    
    return Drawer(
      backgroundColor: bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            accountName: Text(fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? '', style: GoogleFonts.poppins(fontSize: 12)),
            currentAccountPicture: CircleAvatar(
               backgroundColor: accent,
               backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
               child: _photoUrl == null ? const Text('?', style: TextStyle(color: Colors.white, fontSize: 24)) : null,
            ),
          ),
          ListTile(leading: const Icon(LucideIcons.home, color: Colors.white), title: const Text('Beranda', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
          
          const Divider(color: Colors.grey),
          
          // --- MENU KHUSUS ADMIN / CONTRIBUTOR ---
          ListTile(
            leading: const Icon(LucideIcons.uploadCloud, color: Colors.orange), 
            title: const Text('Admin Dashboard', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), 
            onTap: () {
              Navigator.pop(context);
              // Masuk ke Halaman Input Data
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
            }
          ),

          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.redAccent), 
            title: const Text('Keluar', style: TextStyle(color: Colors.redAccent)), 
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(Color bgDark, Color accentBlue) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Carousel (Sementara Dummy dulu biar cantik)
          _buildHeroCarousel(), 
          const SizedBox(height: 20),
          _buildCategoryPills(accentBlue),
          const SizedBox(height: 20),

          // --- BAGIAN INI SUDAH OTOMATIS DARI SUPABASE ---
          _buildSectionHeader(_selectedCategory == 'Semua' ? 'Kajian Terbaru' : 'Kategori: $_selectedCategory', ''),
          
          // STREAM BUILDER: Nunggu data dari internet
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _kajianStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final data = snapshot.data!;
              
              // Filter Lokal (Klien)
              final displayedList = _selectedCategory == 'Semua' 
                  ? data 
                  : data.where((item) => item['category'] == _selectedCategory).toList();

              if (displayedList.isEmpty) {
                 return SizedBox(height: 100, child: Center(child: Text("Belum ada video", style: GoogleFonts.poppins(color: Colors.grey))));
              }

              // Konversi ke Format List Lama (Biar gak ubah UI bawahnya)
              final List<Map<String, String>> uiList = displayedList.map((e) => {
                'title': e['title'].toString(),
                'author': e['author'].toString(),
                'img': e['thumbnail_url'].toString(),
                'video_url': e['video_url'].toString(),
                // Field lain kasih default biar ga error
                'views': 'New',
                'date': 'Baru saja',
              }).toList();

              return _buildHorizontalList(uiList, isLarge: true);
            },
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- WIDGET PENDUKUNG (Nav, AppBar, dll - Copas aja biar rapi) ---
  // (Bagian ini sama persis kayak sebelumnya, saya persingkat biar muat)
  Widget _buildBottomNav(Color bg, Color accent) {
     return Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade900, width: 0.5))), child: BottomNavigationBar(backgroundColor: bg.withOpacity(0.95), selectedItemColor: accent, unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index), items: const [BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'), BottomNavigationBarItem(icon: Icon(LucideIcons.compass), label: 'Jelajah'), BottomNavigationBarItem(icon: Icon(LucideIcons.bookmark), label: 'Saved'), BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profil')]));
  }

  PreferredSizeWidget _buildHomeAppBar({required Color cardDark}) {
    return AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: Builder(builder: (context) => IconButton(icon: const Icon(LucideIcons.alignLeft, color: Colors.white), onPressed: () => Scaffold.of(context).openDrawer())), title: Text('SANADFLOW', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 22, color: Colors.white)), actions: [Padding(padding: const EdgeInsets.only(right: 16), child: GestureDetector(onTap: () => setState(() => _currentIndex = 3), child: CircleAvatar(backgroundColor: cardDark, radius: 16, backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null, child: _photoUrl == null ? const Icon(Icons.person, size: 16, color: Colors.white) : null)))]);
  }
  
  Widget _buildCategoryPills(Color accent) {
    final categories = ['Semua', 'Fiqih', 'Aqidah', 'Parenting', 'Sejarah'];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: categories.map((cat) { final isActive = cat == _selectedCategory; return GestureDetector(onTap: () => setState(() => _selectedCategory = cat), child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, border: Border.all(color: isActive ? Colors.white : Colors.grey.shade800), borderRadius: BorderRadius.circular(30)), child: Text(cat, style: GoogleFonts.poppins(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.w600)))); }).toList()));
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), if(action.isNotEmpty) Text(action, style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 14, fontWeight: FontWeight.w600))]));
  }

  Widget _buildHorizontalList(List<Map<String, String>> data, {required bool isLarge}) {
    return SizedBox(height: isLarge ? 220 : 160, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: data.length, separatorBuilder: (context, index) => const SizedBox(width: 12), itemBuilder: (context, index) { final item = data[index]; return GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: item))), child: SizedBox(width: isLarge ? 150 : 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: item['img']!, fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white)), placeholder: (context, url) => Shimmer.fromColors(baseColor: Colors.grey[900]!, highlightColor: Colors.grey[800]!, child: Container(color: Colors.black))))), const SizedBox(height: 8), Text(item['title']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)), Text(item['author']!, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12))]))); }));
  }

  Widget _buildHeroCarousel() { return Stack(children: [CarouselSlider(options: CarouselOptions(height: 500, viewportFraction: 1.0, autoPlay: true), items: ['https://images.unsplash.com/photo-1542816417-0983c9c9ad53?q=80&w=1000'].map((i) => CachedNetworkImage(imageUrl: i, fit: BoxFit.cover, width: double.infinity)).toList()), Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.1), const Color(0xFF121212)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))), Positioned(bottom: 30, left: 20, right: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF2962FF), borderRadius: BorderRadius.circular(4)), child: Text('KAJIAN PILIHAN', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(height: 10), Text('Keutamaan Ilmu & \nAdab Penuntutnya', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2))]))]); }
}