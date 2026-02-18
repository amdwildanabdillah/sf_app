import 'dart:ui'; // WAJIB ADA BUAT EFEK KACA (BLUR)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// --- IMPORT HALAMAN LAIN ---
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';
import 'package:sanadflow_mobile/screens/explore_screen.dart';
import 'package:sanadflow_mobile/screens/saved_screen.dart';
import 'package:sanadflow_mobile/screens/profile_screen.dart';
import 'package:sanadflow_mobile/screens/login_screen.dart';
import 'package:sanadflow_mobile/screens/dashboard_screen.dart'; 
import 'package:sanadflow_mobile/screens/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABLES ---
  int _currentIndex = 0; 
  String _selectedCategory = 'Semua'; 
  final user = Supabase.instance.client.auth.currentUser;

  // --- QUERY UTAMA: AMBIL DARI VIEW 'kajian_lengkap' ---
  final Future<List<Map<String, dynamic>>> _kajianFuture = Supabase.instance.client
      .from('kajian_lengkap')
      .select()
      .order('created_at', ascending: false);

  String? get _photoUrl {
    final metadata = user?.userMetadata;
    return metadata?['avatar_url'] ?? metadata?['picture'];
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF121212); 
    const accentBlue = Color(0xFF2962FF); 

    // LIST HALAMAN UTAMA
    final List<Widget> pages = [
      _buildHomeContent(bgDark, accentBlue), // Halaman 0
      const ExploreScreen(),                 // Halaman 1
      const SavedScreen(),                   // Halaman 2
      const ProfileScreen(),                 // Halaman 3
    ];

    return Scaffold(
      backgroundColor: bgDark,
      extendBody: true, 
      extendBodyBehindAppBar: true, 
      
      // HEADER GLASSMORPHISM (Hanya muncul di Home)
      appBar: _currentIndex == 0 ? _buildGlassAppBar(cardDark: Colors.white.withOpacity(0.1)) : null,
      
      // SIDEBAR MENU (YANG UDAH DIBENERIN)
      drawer: _currentIndex == 0 ? _buildDrawer(bgDark, accentBlue) : null,
      
      body: pages[_currentIndex],
      bottomNavigationBar: _buildGlassBottomNav(bgDark, accentBlue),
    );
  }

  // ===============================================================
  // 1. KONTEN HOME (SCROLLABLE)
  // ===============================================================
  Widget _buildHomeContent(Color bgDark, Color accentBlue) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCarousel(), 
          const SizedBox(height: 20),
          _buildCategoryPills(accentBlue),
          const SizedBox(height: 20),
          _buildSectionHeader(_selectedCategory == 'Semua' ? 'Kajian Terbaru' : 'Kategori: $_selectedCategory', ''),
          
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _kajianFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: Color(0xFF2962FF))));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return SizedBox(height: 100, child: Center(child: Text("Belum ada video", style: GoogleFonts.poppins(color: Colors.grey))));
              }
              
              final data = snapshot.data!;
              final displayedList = _selectedCategory == 'Semua' 
                  ? data 
                  : data.where((item) => item['category'] == _selectedCategory).toList();

              if (displayedList.isEmpty) {
                return SizedBox(height: 100, child: Center(child: Text("Kategori ini kosong", style: GoogleFonts.poppins(color: Colors.grey))));
              }

              final List<Map<String, String>> uiList = displayedList.map((e) => {
                'title': e['title'].toString(),
                'author': e['dai_name']?.toString() ?? 'Ustadz', 
                'img': e['thumbnail_url']?.toString() ?? '',
                'video_url': e['video_url'].toString(),
                'desc': e['description']?.toString() ?? '',
                'category': e['category']?.toString() ?? 'Umum',
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
  // 2. WIDGET CAROUSEL
  // ===============================================================
  Widget _buildHeroCarousel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('kajian_lengkap').select().eq('is_featured', true).limit(5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildSingleHeroItem(
            title: "Selamat Datang di SanadFlow",
            tag: "SanadFlow",
            imageUrl: "https://images.unsplash.com/photo-1542816417-0983c9c9ad53?q=80&w=1000",
            onTap: () {},
          );
        }

        final featuredList = snapshot.data!;

        return CarouselSlider(
          options: CarouselOptions(
            height: 500, viewportFraction: 1.0, autoPlay: featuredList.length > 1, autoPlayInterval: const Duration(seconds: 5),
          ),
          items: featuredList.map((item) {
            return _buildSingleHeroItem(
              title: item['title'] ?? 'Tanpa Judul',
              tag: item['category'] ?? 'Umum',
              imageUrl: item['thumbnail_url'] ?? '',
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: {
                   'title': item['title'],
                   'author': item['dai_name'] ?? 'Ustadz',
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

  Widget _buildSingleHeroItem({required String title, required String tag, required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/500', 
            fit: BoxFit.cover, width: double.infinity, height: 500,
            errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.4), Colors.transparent, const Color(0xFF121212)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.4, 1.0]))
            )
          ),
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF2962FF).withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                  child: Text(tag.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.left, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ===============================================================
  // 3. WIDGET LIST VIDEO HORIZONTAL
  // ===============================================================
  Widget _buildHorizontalList(List<Map<String, String>> data, {required bool isLarge}) {
    return SizedBox(
      height: isLarge ? 220 : 160, 
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: data.length, separatorBuilder: (context, index) => const SizedBox(width: 12), 
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
                        imageUrl: item['img']!, fit: BoxFit.cover, width: double.infinity,
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

  // ===============================================================
  // 4. HEADER GLASSMORPHISM (APP BAR)
  // ===============================================================
  PreferredSizeWidget _buildGlassAppBar({required Color cardDark}) {
    return AppBar(
      backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withOpacity(0.3)))),
      leading: Builder(builder: (context) => IconButton(icon: const Icon(LucideIcons.alignLeft, color: Colors.white), onPressed: () => Scaffold.of(context).openDrawer())),
      title: Text('SANADFLOW', style: GoogleFonts.poppins(fontWeight: FontWeight.w300, letterSpacing: 4, fontSize: 20, color: Colors.white)),
      actions: [
        Padding(padding: const EdgeInsets.only(right: 20), child: GestureDetector(onTap: () => setState(() => _currentIndex = 3), child: CircleAvatar(backgroundColor: cardDark, radius: 16, backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null, child: _photoUrl == null ? const Icon(Icons.person, size: 16, color: Colors.white) : null)))
      ]
    );
  }

  // ===============================================================
  // 5. SIDEBAR MENU (YANG UDAH DIBALIKIN)
  // ===============================================================
  Widget _buildDrawer(Color bg, Color accent) {
    final String fullName = user?.userMetadata?['full_name'] ?? 'Tamu';
    final String email = user?.email ?? '';

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER PROFIL (BALIK LAGI) ---
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

            // --- MENU UTAMA ---
            _drawerItem(LucideIcons.layoutDashboard, "Dashboard Admin", () {
                Navigator.pop(context); 
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

            // --- MENU SUPPORT ---
            _drawerItem(LucideIcons.info, "Tentang Aplikasi", () {
               Navigator.pop(context); 
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            }),

            _drawerItem(LucideIcons.messageCircle, "Hubungi Pengembang", () {
               Navigator.pop(context);
               _openWhatsApp(); 
            }, color: Colors.greenAccent), 

            const Spacer(),
            
            // --- LOGOUT ---
            const Divider(color: Colors.white10),
            _drawerItem(LucideIcons.logOut, "Keluar", () async {
                 await Supabase.instance.client.auth.signOut(); 
                 if(mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
               }, color: Colors.redAccent),
             const SizedBox(height: 20),
          ]
        )
      )
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

  // ===============================================================
  // 6. NAVBAR & KATEGORI
  // ===============================================================
  Widget _buildGlassBottomNav(Color bg, Color accent) {
     return Container(color: Colors.transparent, padding: const EdgeInsets.fromLTRB(30, 0, 30, 30), child: ClipRRect(borderRadius: BorderRadius.circular(50), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(height: 55, decoration: BoxDecoration(color: const Color(0xFF1E1E1E).withOpacity(0.6), borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_navIcon(LucideIcons.home, 0, accent), _navIcon(LucideIcons.compass, 1, accent), _navIcon(LucideIcons.bookmark, 2, accent), _navIcon(LucideIcons.user, 3, accent)])))));
  }

  Widget _navIcon(IconData icon, int index, Color accent) {
    final isActive = _currentIndex == index;
    return GestureDetector(onTap: () => setState(() => _currentIndex = index), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(10), decoration: isActive ? BoxDecoration(color: accent.withOpacity(0.3), shape: BoxShape.circle) : const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle), child: Icon(icon, color: isActive ? Colors.white : Colors.grey[400], size: 22)));
  }
  
  Widget _buildCategoryPills(Color accent) {
    final categories = ['Semua', 'Fiqih', 'Aqidah', 'Parenting', 'Sejarah'];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: categories.map((cat) { final isActive = cat == _selectedCategory; return GestureDetector(onTap: () => setState(() => _selectedCategory = cat), child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, border: Border.all(color: isActive ? Colors.white : Colors.grey.shade800), borderRadius: BorderRadius.circular(30)), child: Text(cat, style: GoogleFonts.poppins(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.w600)))); }).toList()));
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), if(action.isNotEmpty) Text(action, style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 14, fontWeight: FontWeight.w600))]));
  }
}