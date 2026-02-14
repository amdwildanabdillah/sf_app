import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _descController = TextEditingController();
  final _sanadController = TextEditingController();

  // Data State
  String? _selectedDaiId;
  String? _selectedCategoryName; // Simpan Nama Kategori
  File? _thumbnailFile;
  
  // List Data dari Database
  List<Map<String, dynamic>> _daiList = [];
  List<Map<String, dynamic>> _categoryList = [];

  @override
  void initState() {
    super.initState();
    _fetchData(); // Ambil Dai & Kategori pas buka halaman
  }

  // --- 1. AMBIL DATA (DAI & KATEGORI) DARI SUPABASE ---
  Future<void> _fetchData() async {
    try {
      // Ambil List Dai
      final responseDai = await Supabase.instance.client
          .from('dais')
          .select('id, name')
          .order('name', ascending: true);
          
      // Ambil List Kategori
      final responseCat = await Supabase.instance.client
          .from('categories')
          .select('name')
          .order('name', ascending: true);
      
      setState(() {
        _daiList = List<Map<String, dynamic>>.from(responseDai);
        _categoryList = List<Map<String, dynamic>>.from(responseCat);
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  // --- 2. LOGIC TAMBAH DAI BARU (POPUP) ---
  Future<void> _showAddDaiDialog() async {
    final daiNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Tambah Dai Baru", style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: daiNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Nama Ustadz / Dai",
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
              if(daiNameController.text.isNotEmpty) {
                await Supabase.instance.client.from('dais').insert({'name': daiNameController.text});
                Navigator.pop(context);
                _fetchData(); // Refresh dropdown
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dai Berhasil Ditambahkan")));
              }
            },
          )
        ],
      )
    );
  }

  // --- 3. LOGIC TAMBAH KATEGORI BARU (POPUP) ---
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
            hintText: "Contoh: Hadits",
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
                  Navigator.pop(context);
                  _fetchData(); // Refresh dropdown
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori Berhasil Ditambahkan")));
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

  // --- 4. PILIH GAMBAR THUMBNAIL ---
  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _thumbnailFile = File(image.path);
      });
    }
  }

  // --- 5. SUBMIT FORM (UPLOAD & INSERT) ---
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
      String? thumbnailUrl;

      // A. Upload Thumbnail (Kalau ada file)
      if (_thumbnailFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'thumbnails/$fileName';
        
        await Supabase.instance.client.storage.from('images').upload(path, _thumbnailFile!);
        thumbnailUrl = Supabase.instance.client.storage.from('images').getPublicUrl(path);
      } 

      // B. Insert Data ke Tabel Kajian
      await Supabase.instance.client.from('kajian').insert({
        'title': _titleController.text,
        'video_url': _videoUrlController.text,
        'dai_id': _selectedDaiId,
        'category': _selectedCategoryName, // Pake Nama Kategori
        'description': _descController.text,
        'sanad_source': _sanadController.text,
        'thumbnail_url': thumbnailUrl, 
        'uploader_id': user?.id,
        'source_type': 'youtube',
        'views': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Alhamdulillah! Kajian berhasil diupload.")));
        Navigator.pop(context); // Balik ke Home
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Gagal upload: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text("Upload Kajian", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
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

              // --- PILIH DAI / USTADZ (DINAMIS) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("Nama Dai / Penceramah"),
                  TextButton.icon(
                    onPressed: _showAddDaiDialog, 
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
                  return DropdownMenuItem<String>(
                    value: dai['id'],
                    child: Text(dai['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDaiId = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),

              const SizedBox(height: 20),

              // --- PILIH KATEGORI (DINAMIS) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("Kategori / Topik"),
                  TextButton.icon(
                    onPressed: _showAddCategoryDialog, 
                    icon: const Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF2962FF)),
                    label: Text("Kategori Baru", style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontSize: 12))
                  )
                ],
              ),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration("Pilih Kategori", LucideIcons.tag),
                value: _selectedCategoryName,
                items: _categoryList.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['name'],
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryName = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),

              const SizedBox(height: 20),

              // --- LINK VIDEO ---
              _buildLabel("Link Video (YouTube)"),
              _buildTextField(_videoUrlController, "https://youtube.com/watch?v=...", icon: LucideIcons.link),

              const SizedBox(height: 20),

              // --- THUMBNAIL UPLOAD ---
              _buildLabel("Thumbnail / Cover"),
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                    image: _thumbnailFile != null 
                      ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover)
                      : null
                  ),
                  child: _thumbnailFile == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.imagePlus, color: Colors.grey, size: 40),
                          const SizedBox(height: 8),
                          Text("Tap untuk upload gambar", style: GoogleFonts.poppins(color: Colors.grey))
                        ],
                      )
                    : null,
                ),
              ),

              const SizedBox(height: 20),

              // --- DESKRIPSI & SANAD ---
              _buildLabel("Deskripsi Singkat"),
              _buildTextField(_descController, "Ringkasan materi kajian...", maxLines: 3),
              
              const SizedBox(height: 16),
              
              _buildLabel("Sumber / Sanad (PENTING)"),
              _buildTextField(_sanadController, "Misal: Kitab Riyadhus Shalihin, Bab 2", icon: LucideIcons.bookOpen),

              const SizedBox(height: 40),

              // --- TOMBOL SUBMIT ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKajian,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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

  // --- WIDGET HELPERS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: (val) => val!.isEmpty ? 'Tidak boleh kosong' : null,
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2962FF))),
    );
  }
}