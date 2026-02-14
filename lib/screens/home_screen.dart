import 'dart:ui'; // WAJIB ADA: Buat efek BLUR kaca
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// --- IMPORT HALAMAN LAIN ---
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';
import 'package:sanadflow_mobile/screens/explore_screen.dart';
import 'package:sanadflow_mobile/screens/saved_screen.dart';
import 'package:sanadflow_mobile/screens/profile_screen.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';
// import 'package:sanadflow_mobile/screens/admin_screen.dart'; // <--- INI KITA GANTI ARAHNYA NANTI KE DASHBOARD
import 'package:sanadflow_mobile/screens/dashboard_screen.dart'; // <--- NAMA FILE BARU BUAT DASHBOARD
import 'package:sanadflow_mobile/screens/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABEL ---
  int _currentIndex = 0; 
  String _selectedCategory = 'Semua'; 

  final user = Supabase.instance.client.auth.currentUser;

  String? get _photoUrl {
    final metadata = user?.userMetadata;
    return metadata?['avatar_url'] ?? metadata?['picture'];
  }

  // STREAM: Pipa data dari Supabase (List Video Bawah)
  final _kajianStream = Supabase.instance.client
      .from('kajian')
      .stream(primaryKey: ['id'])
      .order('id', ascending: false);

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF121212); 
    const accentBlue = Color(0xFF2962FF); 

    final List<Widget> pages = [
      _buildHomeContent(bgDark, accentBlue),
      const ExploreScreen(),
      const SavedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: bgDark,
      extendBody: true, 
      extendBodyBehindAppBar: true, 
      
      // Header Glassmorphism
      appBar: _currentIndex == 0 ? _buildGlassAppBar(cardDark: Colors.white.withOpacity(0.1)) : null,
      drawer: _currentIndex == 0 ? _buildDrawer(bgDark, accentBlue) : null,
      
      body: pages[_currentIndex],
      
      // Navbar Melayang & Blur
      bottomNavigationBar: _buildGlassBottomNav(bgDark, accentBlue),
    );
  }

  // ===============================================================
  // 1. HEADER / APP BAR (GLASSMORPHISM)
  // ===============================================================
  PreferredSizeWidget _buildGlassAppBar({required Color cardDark}) {
    return AppBar(
      backgroundColor: Colors.transparent, 
      elevation: 0,
      centerTitle: true,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(LucideIcons.alignLeft, color: Colors.white), 
          onPressed: () => Scaffold.of(context).openDrawer()
        )
      ),
      title: Text(
        'SANADFLOW', 
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w300, 
          letterSpacing: 4, 
          fontSize: 20, 
          color: Colors.white
        )
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => setState(() => _currentIndex = 3), 
            child: CircleAvatar(
              backgroundColor: cardDark, 
              radius: 16, 
              backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null ? const Icon(Icons.person, size: 16, color: Colors.white) : null
            )
          )
        )
      ]
    );
  }

  // ===============================================================
  // 2. FUNGSI WA & SIDEBAR
  // ===============================================================
  Future<void> _openWhatsApp() async {
    const phoneNumber = '6282232053253'; 
    const message = 'Halo Admin SanadFlow, saya ingin melaporkan masalah / diskusi tentang aplikasi.';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint("Error launching WA: $e");
    }
  }

  Widget _buildDrawer(Color bg, Color accent) {
    final String fullName = user?.userMetadata?['full_name'] ?? 'Tamu';
    final String email = user?.email ?? '';
    
    return Drawer(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER PROFIL
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                      image: _photoUrl != null 
                          ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _photoUrl == null ? const Icon(LucideIcons.user, color: Colors.white54) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(fullName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(email, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),

            // MENU UTAMA
            _drawerItem(LucideIcons.layoutDashboard, "Dashboard Admin", () {
                Navigator.pop(context);
                // ARAHKAN KE DASHBOARD (List Video), BUKAN LANGSUNG UPLOAD
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
            }, color: accent), 
            
            _drawerItem(LucideIcons.history, "Riwayat Tontonan", () {
               Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Segera Hadir!")));
            }),
            _drawerItem(LucideIcons.bookmark, "Koleksi Disimpan", () {
               Navigator.pop(context); 
               setState(() => _currentIndex = 2); 
            }),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10, indent: 24, endIndent: 24), 
            const SizedBox(height: 16),

            // MENU SUPPORT
            _drawerItem(LucideIcons.info, "Tentang Aplikasi", () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())); 
            }),
            _drawerItem(LucideIcons.messageCircle, "Hubungi Pengembang", () {
               Navigator.pop(context);
               _openWhatsApp(); 
            }, color: Colors.greenAccent), 

            const Spacer(), 
            const Divider(color: Colors.white10),
            _drawerItem(LucideIcons.logOut, "Keluar", () async {
               await Supabase.instance.client.auth.signOut();
               if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }, color: Colors.redAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: GoogleFonts.poppins(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  // ===============================================================
  // 3. KONTEN HOME (DENGAN CAROUSEL DINAMIS)
  // ===============================================================
  Widget _buildHomeContent(Color bgDark, Color accentBlue) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CAROUSEL DINAMIS
          _buildHeroCarousel(), 
          
          const SizedBox(height: 20),
          _buildCategoryPills(accentBlue),
          const SizedBox(height: 20),
          _buildSectionHeader(_selectedCategory == 'Semua' ? 'Kajian Terbaru' : 'Kategori: $_selectedCategory', ''),
          
          // LIST VIDEO BAWAH
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _kajianStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error', style: const TextStyle(color: Colors.red)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final data = snapshot.data!;
              final displayedList = _selectedCategory == 'Semua' 
                  ? data 
                  : data.where((item) => item['category'] == _selectedCategory).toList();

              if (displayedList.isEmpty) {
                 return SizedBox(height: 100, child: Center(child: Text("Belum ada video", style: GoogleFonts.poppins(color: Colors.grey))));
              }

              // Konversi Data
              final List<Map<String, String>> uiList = displayedList.map((e) => {
                'title': e['title'].toString(),
                'author': 'Dai', // Nanti update pake relasi
                'img': e['thumbnail_url']?.toString() ?? '',
                'video_url': e['video_url'].toString(),
                'desc': e['description']?.toString() ?? '',
              }).toList();

              return _buildHorizontalList(uiList, isLarge: true);
            },
          ),
          
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  // ===============================================================
  // 4. CAROUSEL DINAMIS (LOGIC BARU)
  // ===============================================================
  Widget _buildHeroCarousel() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Query: Ambil video yang 'is_featured' = true
      stream: Supabase.instance.client
          .from('kajian')
          .stream(primaryKey: ['id'])
          .eq('is_featured', true) 
          .limit(5),
      builder: (context, snapshot) {
        // TAMPILAN DEFAULT (Kalau belum ada Featured)
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildSingleHeroItem(
            title: "Belum Ada Kajian Pilihan",
            tag: "SANADFLOW",
            imageUrl: "https://images.unsplash.com/photo-1542816417-0983c9c9ad53?q=80&w=1000",
            onTap: () {},
          );
        }

        final featuredList = snapshot.data!;

        return CarouselSlider(
          options: CarouselOptions(
            height: 500, 
            viewportFraction: 1.0, 
            autoPlay: featuredList.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: featuredList.map((item) {
            return _buildSingleHeroItem(
              title: item['title'] ?? 'Tanpa Judul',
              tag: item['category'] ?? 'Umum',
              imageUrl: item['thumbnail_url'] ?? '',
              onTap: () {
                 // Navigasi ke Detail
                 Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
                   'title': item['title'],
                   'author': 'SanadFlow',
                   'video_url': item['video_url'],
                   'img': item['thumbnail_url'],
                   'desc': item['description']
                 })));
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSingleHeroItem({
    required String title, 
    required String tag, 
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/500', 
            fit: BoxFit.cover, 
            width: double.infinity, 
            height: 500,
            errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent, const Color(0xFF121212)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.4, 1.0]
                )
              )
            )
          ),
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // <--- BALIKIN KE KIRI (START)
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withOpacity(0.9), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 16),
                Text(
                  title, 
                  textAlign: TextAlign.left, // <--- RATA KIRI
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ===============================================================
  // 5. NAVBAR & WIDGET LAIN (TETAP SAMA)
  // ===============================================================
  Widget _buildGlassBottomNav(Color bg, Color accent) {
    return Container(
      color: Colors.transparent, 
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 30), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
          child: Container(
            height: 55, 
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.6), 
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navIcon(LucideIcons.home, 0, accent), _navIcon(LucideIcons.compass, 1, accent), 
                _navIcon(LucideIcons.bookmark, 2, accent), _navIcon(LucideIcons.user, 3, accent), 
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, Color accent) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10), 
        decoration: isActive ? BoxDecoration(color: accent.withOpacity(0.3), shape: BoxShape.circle) : const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey[400], size: 22),
      ),
    );
  }

  Widget _buildCategoryPills(Color accent) {
    final categories = ['Semua', 'Fiqih', 'Aqidah', 'Parenting', 'Sejarah'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, 
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      child: Row(
        children: categories.map((cat) { 
          final isActive = cat == _selectedCategory; 
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat), 
            child: Container(
              margin: const EdgeInsets.only(right: 10), 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent, 
                border: Border.all(color: isActive ? Colors.white : Colors.grey.shade800), 
                borderRadius: BorderRadius.circular(30)
              ), 
              child: Text(cat, style: GoogleFonts.poppins(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.w600))
            )
          ); 
        }).toList()
      )
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          if(action.isNotEmpty) Text(action, style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 14, fontWeight: FontWeight.w600))
        ]
      )
    );
  }

  Widget _buildHorizontalList(List<Map<String, String>> data, {required bool isLarge}) {
    return SizedBox(
      height: isLarge ? 220 : 160, 
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), 
        scrollDirection: Axis.horizontal, 
        itemCount: data.length, 
        separatorBuilder: (context, index) => const SizedBox(width: 12), 
        itemBuilder: (context, index) { 
          final item = data[index]; 
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: item))), 
            child: SizedBox(
              width: isLarge ? 150 : 220, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8), 
                      child: CachedNetworkImage(
                        imageUrl: item['img']!, 
                        fit: BoxFit.cover, 
                        errorWidget: (context, url, error) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white)), 
                      )
                    )
                  ), 
                  const SizedBox(height: 8), 
                  Text(item['title']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)), 
                  Text(item['author']!, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12))
                ]
              )
            )
          ); 
        }
      )
    );
  }
}