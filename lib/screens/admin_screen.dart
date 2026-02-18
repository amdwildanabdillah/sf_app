import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; 
import 'package:sanadflow_mobile/screens/manage_dai_screen.dart'; // Pastikan file ini ada

class AdminScreen extends StatefulWidget {
  // Parameter ini diisi kalau mode EDIT. Kalau Upload Baru, ini null.
  final Map<String, dynamic>? editData; 

  const AdminScreen({super.key, this.editData});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Controllers Utama
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _descController = TextEditingController();
  final _sanadController = TextEditingController();
  
  // Controllers Clipper / Sumber
  final _sourceNameController = TextEditingController();
  final _sourceUrlController = TextEditingController();

  // Data State
  String? _selectedDaiId;
  String? _selectedCategoryName; 
  File? _thumbnailFile;
  String? _existingThumbnailUrl; // Simpan URL lama buat preview pas edit
  
  // List Dropdown
  List<Map<String, dynamic>> _daiList = [];
  List<Map<String, dynamic>> _categoryList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    
    // LOGIC DETEKSI EDIT MODE
    if (widget.editData != null) {
      _isEditMode = true;
      _fillDataForEdit();
    }
  }

  // ISI FORM DENGAN DATA LAMA (KHUSUS EDIT)
  void _fillDataForEdit() {
    final data = widget.editData!;
    _titleController.text = data['title'] ?? '';
    _videoUrlController.text = data['video_url'] ?? '';
    _descController.text = data['description'] ?? '';
    _sanadController.text = data['sanad_source'] ?? '';
    _sourceNameController.text = data['source_account_name'] ?? '';
    _sourceUrlController.text = data['source_account_url'] ?? '';
    
    // Set Dropdown & Thumbnail
    _selectedDaiId = data['dai_id'];
    _selectedCategoryName = data['category'];
    _existingThumbnailUrl = data['thumbnail_url'];
  }

  // AMBIL DATA PENCERAMAH & KATEGORI DARI DB
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

  // POPUP TAMBAH KATEGORI BARU
  Future<void> _showAddCategoryDialog() async {
    final catController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Tambah Kategori Baru", style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: catController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Contoh: Fiqih Wanita",
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true, fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(child: const Text("Batal"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              if(catController.text.isNotEmpty) {
                try {
                  await Supabase.instance.client.from('categories').insert({'name': catController.text});
                  if (mounted) {
                    Navigator.pop(context);
                    _fetchData(); // Refresh list biar muncul
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori Berhasil Ditambahkan")));
                  }
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal (Mungkin sudah ada)")));
                }
              }
            },
          )
        ],
      )
    );
  }

  // AMBIL GAMBAR DARI GALERI
  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _thumbnailFile = File(image.path));
  }

  // LOGIC SAKTI: SUBMIT (BISA INSERT / UPDATE)
  Future<void> _submitKajian() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDaiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Penceramah dulu!")));
      return;
    }
    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Kategori dulu!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? finalThumbnailUrl = _existingThumbnailUrl; // Default pake yang lama kalau edit

      // Cek Platform (Simple Check)
      String platformType = 'youtube';
      final urlLower = _videoUrlController.text.toLowerCase();
      if (urlLower.contains('instagram.com')) platformType = 'instagram';
      else if (urlLower.contains('tiktok.com')) platformType = 'tiktok';

      // A. LOGIC UPLOAD THUMBNAIL
      if (_thumbnailFile != null) {
        // 1. User upload gambar manual (Prioritas Utama)
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'thumbnails/$fileName';
        await Supabase.instance.client.storage.from('images').upload(path, _thumbnailFile!);
        finalThumbnailUrl = Supabase.instance.client.storage.from('images').getPublicUrl(path);
      } else if (!_isEditMode && platformType == 'youtube') {
        // 2. Kalau BARU & YouTube & Gak upload gambar -> Auto Fetch
        final videoId = YoutubePlayer.convertUrlToId(_videoUrlController.text);
        if (videoId != null) {
          finalThumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        }
      }

      // Validasi: IG/TikTok wajib punya thumbnail (karena gak bisa auto fetch)
      if (platformType != 'youtube' && finalThumbnailUrl == null) {
         throw "Link IG/TikTok wajib upload thumbnail manual!";
      }

      // B. SIAPKAN DATA
      // FIX ERROR: Tambahkan 'Map<String, dynamic>' agar bisa menampung int dan string
      final Map<String, dynamic> dataToSave = {
        'title': _titleController.text,
        'video_url': _videoUrlController.text,
        'dai_id': _selectedDaiId,
        'category': _selectedCategoryName,
        'description': _descController.text,
        'sanad_source': _sanadController.text,
        'thumbnail_url': finalThumbnailUrl, 
        'source_account_name': _sourceNameController.text.isNotEmpty ? _sourceNameController.text : null,
        'source_account_url': _sourceUrlController.text.isNotEmpty ? _sourceUrlController.text : null,
        'platform': platformType,
      };

      if (!_isEditMode) {
        // --- MODE INSERT (BARU) ---
        dataToSave['uploader_id'] = user?.id; // Cuma set uploader pas awal
        dataToSave['views'] = 0; // Int aman masuk sini karena Map<String, dynamic>
        await Supabase.instance.client.from('kajian').insert(dataToSave);
      } else {
        // --- MODE UPDATE (EDIT) ---
        await Supabase.instance.client.from('kajian').update(dataToSave).eq('id', widget.editData!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green, 
          content: Text(_isEditMode ? "Konten Diperbarui!" : "Konten Berhasil Diupload!")
        ));
        Navigator.pop(context, true); // Balik ke Dashboard bawa sinyal "true" (Refresh dong!)
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
        title: Text(_isEditMode ? "Edit Konten" : "Upload Konten", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. JUDUL ---
              _buildLabel("Judul Kajian"),
              _buildTextField(_titleController, "Misal: Keutamaan Sholat Subuh", icon: LucideIcons.type),
              
              const SizedBox(height: 20),

              // --- 2. PENCERAMAH (DROPDOWN + ADD NEW) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("Penceramah / Dai"),
                  TextButton.icon(
                    onPressed: () async {
                      // Buka ManageDaiScreen, tunggu dia balik
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDaiScreen()));
                      if (result == true) _fetchData(); // Refresh list kalau ada dai baru
                    }, 
                    icon: const Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF2962FF)),
                    label: Text("Tambah Baru", style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 12))
                  )
                ],
              ),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration("Pilih Penceramah", LucideIcons.user),
                value: _selectedDaiId,
                items: _daiList.map((dai) {
                  return DropdownMenuItem<String>(value: dai['id'], child: Text(dai['name']));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDaiId = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),

              const SizedBox(height: 20),

              // --- 3. KATEGORI (DROPDOWN + ADD NEW) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildLabel("Kategori"),
                   TextButton.icon(
                    onPressed: _showAddCategoryDialog, 
                    icon: const Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF2962FF)),
                    label: Text("Tambah Kategori", style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 12))
                  )
                ],
              ),
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

              // --- 4. LINK VIDEO ---
              _buildLabel("Link Video (YouTube/IG/TikTok)"),
              _buildTextField(_videoUrlController, "Paste link disini...", icon: LucideIcons.link),

              const SizedBox(height: 20),

              // --- 5. THUMBNAIL (PREVIEW + EDIT) ---
              _buildLabel("Thumbnail"),
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 150, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    image: _thumbnailFile != null 
                      ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover) // Gambar Baru Upload
                      : (_existingThumbnailUrl != null 
                          ? DecorationImage(image: NetworkImage(_existingThumbnailUrl!), fit: BoxFit.cover) // Gambar Lama dari DB
                          : null)
                  ),
                  child: (_thumbnailFile == null && _existingThumbnailUrl == null)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.image, color: Colors.grey, size: 40),
                          const SizedBox(height: 8),
                          Text("Tap untuk upload gambar manual", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                          Text("(Wajib manual jika bukan YouTube)", style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 10)),
                        ],
                      )
                    : null, // Kalau ada gambar, child kosong biar gambarnya kelihatan
                ),
              ),
              if(_isEditMode) Padding(padding:const EdgeInsets.only(top:5), child: Text("*Tap gambar untuk mengganti", style: TextStyle(color: Colors.grey[600], fontSize: 10))),

              const SizedBox(height: 20),

              // --- 6. CLIPPER INFO (OPSIONAL) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(LucideIcons.scissors, size: 16, color: Colors.blue), SizedBox(width: 8), Text("Credit (Clipper / Source)", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11))]),
                    const SizedBox(height: 16),
                    _buildTextField(_sourceNameController, "Nama Akun (Cth: @kajian1menit)", icon: LucideIcons.atSign),
                    const SizedBox(height: 10),
                    _buildTextField(_sourceUrlController, "Link Profil Sosmed Mereka", icon: LucideIcons.link2),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 7. SANAD & DESKRIPSI ---
              _buildLabel("Deskripsi Singkat"),
              _buildTextField(_descController, "Ringkasan materi...", maxLines: 3),
              const SizedBox(height: 12),
              
              _buildLabel("Sumber Referensi / Sanad Ilmu (PENTING)"),
              _buildTextField(
                _sanadController, 
                "Contoh: Kitab Riyadhus Shalihin / Nasihat Umum / Parenting Islami", 
                icon: LucideIcons.bookOpen
              ),

              const SizedBox(height: 40),

              // --- 8. TOMBOL SUBMIT ---
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKajian,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditMode ? "UPDATE KONTEN" : "UPLOAD KONTEN", 
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS (BIAR RAPI) ---
  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: (val) {
        // Clipper & Thumbnail opsional, sisanya wajib
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