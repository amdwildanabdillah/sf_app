import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:sanadflow_mobile/screens/admin_screen.dart'; // IMPORT ADMIN SCREEN BIAR BISA PINDAH

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  bool _isLoading = true;
  String _role = 'viewer'; 
  String _contributorStatus = 'none'; 

  // Variabel Form Upload (Simpel)
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Fiqih';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  // --- 1. CEK IDENTITAS (KEBAL BANTING) ---
  Future<void> _checkRole() async {
    if (user == null) return;
    
    // A. BACKDOOR DEVELOPER (JALUR KHUSUS)
    // Kalau emailnya ini, langsung AUTO ADMIN tanpa tanya database (Biar gak kena lock RLS)
    final email = user!.email ?? '';
    if (email.contains('amd.wildanabdillah') || email.contains('vixel')) {
        if (mounted) {
            setState(() {
                _role = 'admin';
                _contributorStatus = 'approved';
                _isLoading = false;
            });
        }
        return; // Selesai, gak usah tanya database
    }

    // B. JALUR RESMI (DATABASE)
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role, contributor_status')
          .eq('id', user!.id)
          .maybeSingle(); // Pakai maybeSingle biar gak error kalau kosong
      
      if (mounted) {
        setState(() {
          if (data != null) {
             _role = data['role'] ?? 'viewer';
             _contributorStatus = data['contributor_status'] ?? 'none';
          } else {
             // Kalau data profil gak ada, anggap viewer
             _role = 'viewer';
             _contributorStatus = 'none';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // Kalau error koneksi/RLS, tetep anggap viewer
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIC PENGAJUAN ---
  Future<void> _applyForContributor() async {
    setState(() => _isLoading = true);
    try {
      // Update atau Insert (Upsert) biar aman buat user hantu
      await Supabase.instance.client.from('profiles').upsert({
        'id': user!.id,
        'email': user!.email,
        'contributor_status': 'pending',
        'role': 'viewer' // Tetap viewer dulu sampe diacc
      });
      
      if (mounted) {
        setState(() {
          _contributorStatus = 'pending';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengajuan berhasil dikirim!")));
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengajukan.")));
      }
    }
  }

  // --- 3. UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator()));

    // WAJAH 1: VIEW (TAMU / BELUM DIACC)
    if (_role == 'viewer' && _contributorStatus == 'none') {
      return _buildRestrictedView();
    }
    
    // WAJAH 2: PENDING (SEDANG DITINJAU)
    if (_contributorStatus == 'pending' && _role != 'admin') {
      return _buildPendingView();
    }

    // WAJAH 3: WORKSPACE (ADMIN / CONTRIBUTOR)
    String titleText = _role == 'admin' ? "Administrator Panel" : "Contributor Studio";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(titleText, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOMBOL UPLOAD (KALAU ADMIN, BUKA LAYAR ADMIN LENGKAP)
            _buildUploadCard(),
            
            const SizedBox(height: 30),
            Text(_role == 'admin' ? "Semua Konten Masuk" : "Kajian Saya", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildVideoList(),
          ],
        ),
      ),
    );
  }

  // --- VIEW: GEMBOK ---
  Widget _buildRestrictedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: const Icon(LucideIcons.lock, size: 60, color: Colors.redAccent)),
              const SizedBox(height: 24),
              Text("Akses Terbatas", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Area ini khusus untuk Kontributor dan Admin.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _applyForContributor, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)), child: Text("Daftar Jadi Kontributor", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))))
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW: PENDING ---
  Widget _buildPendingView() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.clock, size: 60, color: Colors.orange),
            const SizedBox(height: 24),
            Text("Menunggu Persetujuan", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Akun Anda sedang diverifikasi oleh Admin.", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: CARD UPLOAD (BUTTON ONLY) ---
  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: () {
        // NAVIGASI KE LAYAR UPLOAD LENGKAP (ADMIN SCREEN)
        // Kita pakai AdminScreen yang sudah kamu buat buat handle upload
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
             Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFF2962FF), shape: BoxShape.circle), child: const Icon(LucideIcons.uploadCloud, color: Colors.white)),
             const SizedBox(width: 16),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("Upload Kajian Baru", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 Text("Klik disini untuk mulai upload", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
               ],
             )
          ],
        ),
      ),
    );
  }

  // --- WIDGET: LIST VIDEO ---
  Widget _buildVideoList() {
    // Ambil Data pakai FutureBuilder
    // Kita filter di Client biar aman
    final query = Supabase.instance.client.from('kajian').select().order('created_at', ascending: false);

    return FutureBuilder(
      future: query,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var allData = snapshot.data as List<dynamic>;
        var displayedData = allData;

        // Filter: Kalau bukan admin, cuma liat punya sendiri
        if (_role != 'admin') {
           displayedData = allData.where((item) => item['dai_id'] == user!.id).toList();
        }
        
        if (displayedData.isEmpty) return Center(child: Text("Belum ada konten", style: GoogleFonts.poppins(color: Colors.grey)));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedData.length,
          itemBuilder: (context, index) {
            final item = displayedData[index];
            final isFeatured = item['is_featured'] == true;
            
            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 50, height: 50, color: Colors.black,
                  child: item['thumbnail_url'] != null 
                      ? Image.network(item['thumbnail_url'], fit: BoxFit.cover) 
                      : const Icon(Icons.movie, color: Colors.grey),
                ),
                title: Text(item['title'] ?? 'Tanpa Judul', style: GoogleFonts.poppins(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(isFeatured ? 'Tayang (Featured)' : 'Draft / Regular', style: GoogleFonts.poppins(color: isFeatured ? Colors.green : Colors.orange, fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }
}