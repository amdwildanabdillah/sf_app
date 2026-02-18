import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentProfile();
  }

  // Ambil nama sekarang biar gak ngetik ulang
  Future<void> _fetchCurrentProfile() async {
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user!.id)
          .maybeSingle();
      
      if (data != null && mounted) {
        _nameController.text = data['full_name'] ?? '';
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  // Simpan Perubahan
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama tidak boleh kosong")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update ke Database
      await Supabase.instance.client.from('profiles').upsert({
        'id': user!.id,
        'full_name': _nameController.text,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update Metadata Google (Opsional, biar sinkron)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': _nameController.text})
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Profil Berhasil Diupdate!")));
        Navigator.pop(context, true); // Balik ke profil bawa sinyal "true" (Refresh)
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Gagal: $e")));
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
        title: Text("Edit Profil", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nama Lengkap",
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(LucideIcons.user, color: Colors.grey),
                filled: true, fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("SIMPAN PERUBAHAN", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}