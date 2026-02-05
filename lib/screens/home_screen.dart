import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sanadflow_mobile/screens/about_screen.dart';
import 'package:sanadflow_mobile/screens/video_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<String> heroImages = [
    'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?q=80&w=1000',
    'https://images.unsplash.com/photo-1519817650390-64a93db51149?q=80&w=1000',
  ];

  final List<Map<String, String>> kajianList = [
    {
      'title': 'Parenting Islami: Mendidik Gen Z',
      'author': 'Dr. Aisah Dahlan',
      'img': 'https://i.ytimg.com/vi/M5s0vjC6k74/maxresdefault.jpg',
      'video_url': 'https://www.youtube.com/watch?v=M5s0vjC6k74',
      'source_url': 'https://www.youtube.com/@PecintadrAisahDahlanCHt',
      'views': '1.2M',
      'date': '2 Hari lalu',
      'author_img': 'https://via.placeholder.com/150'
    },
    {
      'title': 'Adab Penuntut Ilmu',
      'author': 'Ustadz Adi Hidayat',
      'img': 'https://i.ytimg.com/vi/F_f-M7zJq5Q/maxresdefault.jpg',
      'video_url': 'https://www.youtube.com/watch?v=F_f-M7zJq5Q',
      'source_url': 'https://www.youtube.com/c/AdiHidayatOfficial',
      'views': '540K',
      'date': '1 Minggu lalu',
      'author_img': 'https://via.placeholder.com/150'
    },
    {
      'title': 'Sejarah Imam Syafi\'i',
      'author': 'Ustadz Hanan Attaki',
      'img': 'https://images.unsplash.com/photo-1596627763784-9195e7834571?w=400',
      'video_url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'source_url': 'https://instagram.com',
      'views': '230K',
      'date': '3 Hari lalu',
      'author_img': 'https://via.placeholder.com/150'
    },
  ];

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF121212);
    const cardDark = Color(0xFF1E1E1E);
    const accentBlue = Color(0xFF2962FF);

    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(LucideIcons.alignLeft, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        title: Text(
          'SANADFLOW', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900, 
            letterSpacing: 2,
            fontSize: 22,
            color: Colors.white
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: cardDark,
              radius: 16,
              backgroundImage: const NetworkImage('https://github.com/wildan.png'),
            ),
          )
        ],
      ),
      drawer: _buildDrawer(bgDark, accentBlue),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCarousel(),
            const SizedBox(height: 20),
            _buildCategoryPills(accentBlue),
            const SizedBox(height: 20),
            _buildSectionHeader('Spesial: Neuro Parenting', 'Lihat Semua'),
            _buildHorizontalList(isLarge: true),
            const SizedBox(height: 10),
            _buildSectionHeader('Baru Diupload', ''),
            _buildHorizontalList(isLarge: false),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 100,
              decoration: BoxDecoration(
                color: accentBlue,
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [accentBlue, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(LucideIcons.code, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Developed by Vixel', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Solusi Digital Kreatif', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade900, width: 0.5))
        ),
        child: BottomNavigationBar(
          backgroundColor: bgDark.withValues(alpha: 0.95), // <-- PERBAIKAN: withValues
          selectedItemColor: accentBlue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.compass), label: 'Jelajah'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.bookmark), label: 'Saved'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 500,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: heroImages.map((imgUrl) {
            return Builder(
              builder: (BuildContext context) {
                return CachedNetworkImage(
                  imageUrl: imgUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[900]!,
                    highlightColor: Colors.grey[800]!,
                    child: Container(color: Colors.black),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // <-- PERBAIKAN: withValues
                colors: [Colors.black.withValues(alpha: 0.1), const Color(0xFF121212)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 30, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF2962FF), borderRadius: BorderRadius.circular(4)),
                child: Text('KAJIAN PILIHAN', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Text('Keutamaan Ilmu & \nAdab Penuntutnya', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {}, 
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {}, 
                    icon: const Icon(LucideIcons.plus, color: Colors.white),
                    label: const Text('My List'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCategoryPills(Color accent) {
    final categories = ['Semua', 'Fiqih', 'Aqidah', 'Parenting', 'Sejarah'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isActive = cat == 'Semua';
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              border: Border.all(color: isActive ? Colors.white : Colors.grey.shade800),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              cat, 
              style: GoogleFonts.poppins(
                color: isActive ? Colors.black : Colors.white, 
                fontWeight: FontWeight.w600
              )
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if(action.isNotEmpty)
            Text(action, style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHorizontalList({required bool isLarge}) {
    return SizedBox(
      height: isLarge ? 220 : 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: kajianList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12), // <-- PERBAIKAN: underscores
        itemBuilder: (context, index) {
          final item = kajianList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailScreen(videoData: item)));
            },
            child: SizedBox(
              width: isLarge ? 150 : 220, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: item['img'] ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[900]!,
                              highlightColor: Colors.grey[800]!,
                              child: Container(color: Colors.black),
                            ),
                            errorWidget: (context, url, error) => Container(color: Colors.grey[900], child: const Icon(Icons.error)),
                          ),
                          Center(
                             child: Container(
                               padding: const EdgeInsets.all(8),
                               // <-- PERBAIKAN: withValues
                               decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                               child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                             ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item['title']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(item['author']!, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(Color bg, Color accent) {
    return Drawer(
      backgroundColor: bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            accountName: Text('Ahmad Wildan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            accountEmail: Text('wildan@vixelcreative.com', style: GoogleFonts.poppins(fontSize: 12)),
            currentAccountPicture: const CircleAvatar(
               backgroundColor: Colors.blue,
               child: Text('W', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          ListTile(leading: const Icon(LucideIcons.home, color: Colors.white), title: const Text('Beranda', style: TextStyle(color: Colors.white)), onTap: () {}),
          ListTile(leading: const Icon(LucideIcons.history, color: Colors.white), title: const Text('Riwayat Tontonan', style: TextStyle(color: Colors.white)), onTap: () {}),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(LucideIcons.info, color: Colors.white), 
            title: const Text('Tentang Aplikasi', style: TextStyle(color: Colors.white)), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            }
          ),
        ],
      ),
    );
  }
}