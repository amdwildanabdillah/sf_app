import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanadflow_mobile/screens/admin_screen.dart';
import 'package:sanadflow_mobile/screens/manage_dai_screen.dart'; // <--- IMPORT MANAGE DAI

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

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  // --- 1. CEK IDENTITAS ---
  Future<void> _checkRole() async {
    if (user == null) return;
    
    // A. BACKDOOR DEVELOPER
    final email = user!.email ?? '';
    if (email.contains('amd.wildanabdillah') || email.contains('vixel')) {
        if (mounted) {
            setState(() {
                _role = 'admin';
                _contributorStatus = 'approved';
                _isLoading = false;
            });
        }
        return; 
    }

    // B. JALUR RESMI
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role, contributor_status')
          .eq('id', user!.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          if (data != null) {
             _role = data['role'] ?? 'viewer';
             _contributorStatus = data['contributor_status'] ?? 'none';
          } else {
             _role = 'viewer';
             _contributorStatus = 'none';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. PENGAJUAN KONTRIBUTOR ---
  Future<void> _applyForContributor() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user!.id,
        'email': user!.email,
        'contributor_status': 'pending',
        'role': 'viewer'
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

  // --- 3. PIN / UNPIN ---
  Future<void> _togglePin(String id, bool currentStatus) async {
    try {
      await Supabase.instance.client.from('kajian').update({
        'is_featured': !currentStatus 
      }).eq('id', id);
      
      setState(() {}); 
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        content: Text(!currentStatus ? "Pinned! (Masuk Highlight)" : "Unpinned (Hapus dari Highlight)")
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update pin: $e")));
    }
  }

  // --- 4. HAPUS KONTEN ---
  Future<void> _deleteKajian(String id) async {
    final confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Hapus Konten?", style: TextStyle(color: Colors.white)),
        content: const Text("Tindakan ini tidak bisa dibatalkan.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("HAPUS", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('kajian').delete().eq('id', id);
        setState(() {}); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konten dihapus.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus.")));
      }
    }
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator()));

    if (_role == 'viewer' && _contributorStatus == 'none') return _buildRestrictedView();
    if (_contributorStatus == 'pending' && _role != 'admin') return _buildPendingView();

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
            // TOMBOL UPLOAD VIDEO BARU
            _buildUploadCard(),
            
            const SizedBox(height: 16),
            
            // TOMBOL KELOLA DAI (KHUSUS ADMIN)
            if (_role == 'admin') _buildManageDaiCard(),
            
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_role == 'admin' ? "Semua Konten Masuk" : "Kajian Saya", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => setState((){}), icon: const Icon(LucideIcons.refreshCw, color: Colors.grey, size: 18)) 
              ],
            ),
            const SizedBox(height: 16),
            _buildVideoList(),
          ],
        ),
      ),
    );
  }

  // --- SUB-WIDGETS ---

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

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
        if (result == true) setState(() {}); 
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
                 Text("Upload Konten Baru", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 Text("Klik disini untuk mulai upload", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
               ],
             )
          ],
        ),
      ),
    );
  }

  // --- MENU BARU: KELOLA DATABASE DAI (Hanya Muncul Buat Admin) ---
  Widget _buildManageDaiCard() {
    return GestureDetector(
      onTap: () {
        // Arahkan ke Halaman Nambah Dai (Atau kalau perlu layar khusus list Dai bisa ditambahin nanti)
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDaiScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
        child: Row(
          children: [
             Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(LucideIcons.users, color: Colors.blueAccent)),
             const SizedBox(width: 16),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("Kelola Database Dai", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 Text("Tambah profil Penceramah & Sanad", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList() {
    final query = Supabase.instance.client.from('kajian').select().order('created_at', ascending: false);

    return FutureBuilder(
      future: query,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var allData = snapshot.data as List<dynamic>;
        var displayedData = allData;

        if (_role != 'admin') {
           displayedData = allData.where((item) => item['uploader_id'] == user!.id).toList();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isFeatured ? BorderSide(color: Colors.orange.withOpacity(0.5), width: 1) : BorderSide.none
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    Container(
                      width: 60, height: 60, 
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        image: item['thumbnail_url'] != null 
                          ? DecorationImage(image: NetworkImage(item['thumbnail_url']), fit: BoxFit.cover)
                          : null
                      ),
                      child: item['thumbnail_url'] == null ? const Icon(Icons.movie, color: Colors.grey) : null,
                    ),
                    if (isFeatured)
                      const Positioned(top: 0, left: 0, child: Icon(Icons.star, size: 16, color: Colors.orange))
                  ],
                ),
                title: Text(item['title'] ?? 'Tanpa Judul', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['category'] ?? 'Umum', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                    if (isFeatured) Text("Featured / Highlight", style: GoogleFonts.poppins(color: Colors.orange, fontSize: 10)),
                  ],
                ),
                
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF2C2C2C),
                  itemBuilder: (context) => [
                    if (_role == 'admin')
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(children: [
                          Icon(isFeatured ? LucideIcons.pinOff : LucideIcons.pin, color: isFeatured ? Colors.orange : Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(isFeatured ? "Unpin (Lepas)" : "Pin to Top", style: const TextStyle(color: Colors.white))
                        ]),
                      ),
                    
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: const [Icon(LucideIcons.edit, color: Colors.blue, size: 18), SizedBox(width: 10), Text("Edit", style: TextStyle(color: Colors.white))]),
                    ),
                    
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: const [Icon(LucideIcons.trash2, color: Colors.red, size: 18), SizedBox(width: 10), Text("Hapus", style: TextStyle(color: Colors.white))]),
                    ),
                  ],
                  onSelected: (val) async {
                    if (val == 'pin') _togglePin(item['id'], isFeatured);
                    if (val == 'delete') _deleteKajian(item['id']);
                    if (val == 'edit') {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen(editData: item)));
                        if (res == true) setState((){}); 
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}