import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageDaiScreen extends StatefulWidget {
  const ManageDaiScreen({super.key});

  @override
  State<ManageDaiScreen> createState() => _ManageDaiScreenState();
}

class _ManageDaiScreenState extends State<ManageDaiScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _igController = TextEditingController();
  final _ytController = TextEditingController();
  final _tiktokController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _saveDai() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama wajib diisi")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('dais').insert({
        'name': _nameController.text,
        'bio': _bioController.text,
        'instagram_url': _igController.text.isNotEmpty ? _igController.text : null,
        'youtube_channel': _ytController.text.isNotEmpty ? _ytController.text : null,
        'tiktok_url': _tiktokController.text.isNotEmpty ? _tiktokController.text : null,
        // 'avatar_url': Nanti bisa ditambahin upload foto ustadz
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Dai Berhasil Disimpan")));
        Navigator.pop(context, true); // Balik dan kasih sinyal refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text("Tambah Database Dai", style: GoogleFonts.poppins(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _inputField("Nama Penceramah", _nameController, icon: LucideIcons.user),
            const SizedBox(height: 16),
            _inputField("Bio Singkat", _bioController, maxLines: 3),
            const SizedBox(height: 16),
            _inputField("Link Instagram", _igController, icon: LucideIcons.instagram),
            const SizedBox(height: 16),
            _inputField("Link Channel YouTube", _ytController, icon: LucideIcons.youtube),
            const SizedBox(height: 16),
            _inputField("Link TikTok", _tiktokController, icon: Icons.tiktok), // Pake icon material
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDai,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text("SIMPAN DATA", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, {IconData? icon, int maxLines = 1}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true, fillColor: const Color(0xFF1E1E1E),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}