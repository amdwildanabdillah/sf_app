import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller buat form
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbUrlController = TextEditingController();
  String _selectedCategory = 'Fiqih'; // Default
  bool _isLoading = false;

  final List<String> categories = ['Fiqih', 'Aqidah', 'Parenting', 'Sejarah', 'Umum'];

  // Fungsi Simpan ke Supabase
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('kajian').insert({
        'title': _titleController.text,
        'author': _authorController.text,
        'video_url': _videoUrlController.text,
        'thumbnail_url': _thumbUrlController.text.isEmpty 
            ? 'https://via.placeholder.com/300' // Default kalau kosong
            : _thumbUrlController.text,
        'category': _selectedCategory,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video Berhasil Ditambahkan!'), backgroundColor: Colors.green),
        );
        // Reset Form
        _titleController.clear();
        _authorController.clear();
        _videoUrlController.clear();
        _thumbUrlController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tambah Kajian Baru", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _buildTextField("Judul Kajian", _titleController),
              _buildTextField("Nama Ustadz", _authorController),
              _buildTextField("Link Video (YouTube/TikTok)", _videoUrlController),
              _buildTextField("Link Thumbnail (Gambar)", _thumbUrlController, isOptional: true),

              const SizedBox(height: 16),
              const Text("Kategori", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              
              // Dropdown Kategori
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800)
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1E1E1E),
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitData,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(LucideIcons.save),
                  label: Text(_isLoading ? "Menyimpan..." : "Posting Video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        validator: (value) => (value == null || value.isEmpty) && !isOptional ? "Wajib diisi" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800)),
        ),
      ),
    );
  }
}