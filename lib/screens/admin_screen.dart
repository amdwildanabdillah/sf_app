import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // PASTIIN IMPORT INI ADA
import 'package:sanadflow_mobile/screens/manage_dai_screen.dart'; // IMPORT FORM DAI

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers Utama
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _descController = TextEditingController();
  final _sanadController = TextEditingController();
  
  // Controllers Tambahan (Clipper/Source)
  final _sourceNameController = TextEditingController(); // Nama akun clipper (Opsional)
  final _sourceUrlController = TextEditingController();  // Link profil clipper (Opsional)

  // Data State
  String? _selectedDaiId;
  String? _selectedCategoryName; 
  File? _thumbnailFile;
  
  // List Data
  List<Map<String, dynamic>> _daiList = [];
  List<Map<String, dynamic>> _categoryList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- 1. AMBIL DATA DAI & KATEGORI ---
  Future<void> _fetchData() async {
    try {
      final responseDai = await Supabase.instance.client
          .from('dais')
          .select('id, name')
          .order('name', ascending: true);
          
      final responseCat = await Supabase.instance.client
          .from('categories')
          .select('name')
          .order('name', ascending: true);
      
      if (mounted) {
        setState(() {
          _daiList = List<Map<String, dynamic>>.from(responseDai);
          _categoryList = List<Map<String, dynamic>>.from(responseCat);
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  // --- 2. PILIH GAMBAR MANUAL ---
  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _thumbnailFile = File(image.path));
  }

  // --- 3. SUBMIT FORM (LOGIC PINTAR) ---
  Future<void> _submitKajian() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDaiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Dai dulu!")));
      return;
    }
    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Kategori dulu!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? finalThumbnailUrl;

      // A. LOGIC THUMBNAIL PINTAR
      if (_thumbnailFile != null) {
        // 1. Kalau user upload gambar manual, pakai itu
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'thumbnails/$fileName';
        await Supabase.instance.client.storage.from('images').upload(path, _thumbnailFile!);
        finalThumbnailUrl = Supabase.instance.client.storage.from('images').getPublicUrl(path);
      } else {
        // 2. Kalau GAK upload, coba ambil dari YouTube ID
        final videoId = YoutubePlayer.convertUrlToId(_videoUrlController.text);
        if (videoId != null) {
          // Pakai link thumbnail resmi YouTube (Resolusi Tinggi)
          finalThumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        }
      }

      // B. INSERT DATA
      await Supabase.instance.client.from('kajian').insert({
        'title': _titleController.text,
        'video_url': _videoUrlController.text,
        'dai_id': _selectedDaiId,
        'category': _selectedCategoryName,
        'description': _descController.text,
        'sanad_source': _sanadController.text,
        'thumbnail_url': finalThumbnailUrl, // Bisa URL gambar upload atau URL YouTube
        'uploader_id': user?.id,
        'source_type': 'youtube',
        'views': 0,
        // Data Baru (Clipper)
        'source_account_name': _sourceNameController.text.isNotEmpty ? _sourceNameController.text : null,
        'source_account_url': _sourceUrlController.text.isNotEmpty ? _sourceUrlController.text : null,
        'platform': 'youtube' // Default youtube dulu
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Kajian Berhasil Diupload!")));
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text("Upload Konten", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- JUDUL ---
              _buildLabel("Judul Kajian"),
              _buildTextField(_titleController, "Misal: Keutamaan Sholat Subuh", icon: LucideIcons.type),
              
              const SizedBox(height: 20),

              // --- PILIH DAI (CONNECT KE MANAGE DAI) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("Penceramah / Dai"),
                  TextButton.icon(
                    onPressed: () async {
                      // Buka halaman tambah Dai yang lengkap
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDaiScreen()));
                      if (result == true) _fetchData();
                    }, 
                    icon: const Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF2962FF)),
                    label: Text("Dai Baru", style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 12))
                  )
                ],
              ),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration("Pilih Ustadz", LucideIcons.user),
                value: _selectedDaiId,
                items: _daiList.map((dai) {
                  return DropdownMenuItem<String>(value: dai['id'], child: Text(dai['name']));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDaiId = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),

              const SizedBox(height: 20),

              // --- KATEGORI ---
              _buildLabel("Kategori"),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration("Pilih Kategori", LucideIcons.tag),
                value: _selectedCategoryName,
                items: _categoryList.map((cat) {
                  return DropdownMenuItem<String>(value: cat['name'], child: Text(cat['name']));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryName = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),

              const SizedBox(height: 20),

              // --- LINK & THUMBNAIL ---
              _buildLabel("Link Video (YouTube)"),
              _buildTextField(_videoUrlController, "https://youtube.com/...", icon: LucideIcons.link),

              const SizedBox(height: 20),

              _buildLabel("Thumbnail (Opsional)"),
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 150, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    image: _thumbnailFile != null ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover) : null
                  ),
                  child: _thumbnailFile == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.image, color: Colors.grey, size: 40),
                          const SizedBox(height: 8),
                          Text("Tap untuk upload manual", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                          Text("(Atau biarkan kosong, otomatis ambil dari YouTube)", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
                        ],
                      )
                    : null,
                ),
              ),

              const SizedBox(height: 20),

              // --- CLIPPER / SUMBER (OPSIONAL) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(LucideIcons.scissors, size: 16, color: Colors.blue), SizedBox(width: 8), Text("Info Clipper / Reposter (Opsional)", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 16),
                    _buildTextField(_sourceNameController, "Nama Akun (Cth: @kajian1menit)", icon: LucideIcons.atSign),
                    const SizedBox(height: 10),
                    _buildTextField(_sourceUrlController, "Link Profil (IG/TikTok/dll)", icon: LucideIcons.link2),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- DESKRIPSI & SANAD ---
              _buildLabel("Deskripsi Singkat"),
              _buildTextField(_descController, "Ringkasan materi...", maxLines: 3),
              const SizedBox(height: 16),
              _buildLabel("Sumber / Sanad (PENTING)"),
              _buildTextField(_sanadController, "Misal: Kitab Riyadhus Shalihin, Bab 2", icon: LucideIcons.bookOpen),

              const SizedBox(height: 40),

              // --- SUBMIT ---
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKajian,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("UPLOAD KAJIAN", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: (val) {
        // Clipper & Thumbnail itu Opsional, jadi gak usah validator wajib
        if (controller == _sourceNameController || controller == _sourceUrlController) return null;
        return val!.isEmpty ? 'Wajib diisi' : null;
      },
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true, fillColor: const Color(0xFF1E1E1E),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2962FF))),
    );
  }
}