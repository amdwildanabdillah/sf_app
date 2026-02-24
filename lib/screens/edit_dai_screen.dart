import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditDaiScreen extends StatefulWidget {
  final String daiId;

  const EditDaiScreen({super.key, required this.daiId});

  @override
  State<EditDaiScreen> createState() => _EditDaiScreenState();
}

class _EditDaiScreenState extends State<EditDaiScreen> {
  // Controller Data Utama Dai
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarController = TextEditingController();
  final _igController = TextEditingController();
  final _ytController = TextEditingController();
  final _tiktokController = TextEditingController();
  
  // State untuk List Dinamis Riwayat Sanad
  List<Map<String, dynamic>> _sanadForms = [];
  bool _isLoading = true; // Buat loading awal saat narik data
  bool _isSaving = false; // Buat loading pas tombol simpan ditekan

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // AMBIL DATA DARI SUPABASE BUAT NGISI FORM
  Future<void> _loadExistingData() async {
    try {
      // 1. Ambil Data Dai
      final daiData = await Supabase.instance.client
          .from('dais')
          .select()
          .eq('id', widget.daiId)
          .single();

      // 2. Ambil Data Sanad
      final sanadData = await Supabase.instance.client
          .from('dai_sanads')
          .select()
          .eq('dai_id', widget.daiId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          // Isi form Dai
          _nameController.text = daiData['name'] ?? '';
          _bioController.text = daiData['bio'] ?? '';
          _avatarController.text = daiData['avatar_url'] ?? '';
          _igController.text = daiData['instagram_url'] ?? '';
          _ytController.text = daiData['youtube_channel'] ?? '';
          _tiktokController.text = daiData['tiktok_url'] ?? '';

          // Isi form Sanad Dinamis
          _sanadForms = (sanadData as List).map((sanad) {
            return {
              'namaController': TextEditingController(text: sanad['nama_instansi_guru'] ?? ''),
              'kategori': sanad['kategori'] ?? 'Pesantren',
              'periodeController': TextEditingController(text: sanad['periode'] ?? ''),
              'deskripsiController': TextEditingController(text: sanad['deskripsi'] ?? ''),
              'websiteController': TextEditingController(text: sanad['website_url'] ?? ''),
            };
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load edit data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
        Navigator.pop(context); // Balik kalau gagal
      }
    }
  }

  void _addSanadForm() {
    setState(() {
      _sanadForms.add({
        'namaController': TextEditingController(),
        'kategori': 'Pesantren',
        'periodeController': TextEditingController(),
        'deskripsiController': TextEditingController(),
        'websiteController': TextEditingController(),
      });
    });
  }

  void _removeSanadForm(int index) {
    setState(() => _sanadForms.removeAt(index));
  }

  // PROSES UPDATE DATA BERANTAI
  Future<void> _updateDai() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama Penceramah wajib diisi!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. UPDATE Tabel 'dais'
      await Supabase.instance.client.from('dais').update({
        'name': _nameController.text,
        'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
        'avatar_url': _avatarController.text.isNotEmpty ? _avatarController.text : null,
        'instagram_url': _igController.text.isNotEmpty ? _igController.text : null,
        'youtube_channel': _ytController.text.isNotEmpty ? _ytController.text : null,
        'tiktok_url': _tiktokController.text.isNotEmpty ? _tiktokController.text : null,
      }).eq('id', widget.daiId);

      // 2. REFRESH Tabel 'dai_sanads' (Cara Gampang: Hapus semua sanad lama, insert yang baru dari form)
      await Supabase.instance.client.from('dai_sanads').delete().eq('dai_id', widget.daiId);

      if (_sanadForms.isNotEmpty) {
        List<Map<String, dynamic>> sanadDataToInsert = [];
        for (var form in _sanadForms) {
          if (form['namaController'].text.isNotEmpty) {
            sanadDataToInsert.add({
              'dai_id': widget.daiId,
              'nama_instansi_guru': form['namaController'].text,
              'kategori': form['kategori'],
              'periode': form['periodeController'].text.isNotEmpty ? form['periodeController'].text : null,
              'deskripsi': form['deskripsiController'].text.isNotEmpty ? form['deskripsiController'].text : null,
              'website_url': form['websiteController'].text.isNotEmpty ? form['websiteController'].text : null,
            });
          }
        }
        if (sanadDataToInsert.isNotEmpty) {
          await Supabase.instance.client.from('dai_sanads').insert(sanadDataToInsert);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Berhasil Diperbarui!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Balik ke layar sebelumnya & kasih sinyal refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2962FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text("Edit Profil Dai", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Profil Penceramah", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _inputField("Nama Penceramah *", _nameController, icon: LucideIcons.user),
            const SizedBox(height: 12),
            _inputField("URL Foto (Avatar)", _avatarController, icon: LucideIcons.image),
            const SizedBox(height: 12),
            _inputField("Bio Singkat", _bioController, maxLines: 3),
            const SizedBox(height: 12),
            _inputField("Link Instagram", _igController, icon: LucideIcons.instagram),
            const SizedBox(height: 12),
            _inputField("Link YouTube", _ytController, icon: LucideIcons.youtube),
            const SizedBox(height: 12),
            _inputField("Link TikTok", _tiktokController, icon: Icons.tiktok),
            
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("2. Riwayat Sanad / Pendidikan", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  onPressed: _addSanadForm,
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                )
              ],
            ),
            const SizedBox(height: 16),

            ..._sanadForms.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> form = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Riwayat #${index + 1}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        InkWell(onTap: () => _removeSanadForm(index), child: const Icon(Icons.delete, color: Colors.redAccent, size: 20))
                      ],
                    ),
                    const SizedBox(height: 12),
                    _inputField("Nama Guru / Instansi *", form['namaController'], icon: LucideIcons.bookOpen),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: form['kategori'],
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Kategori", labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true, fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Pesantren', 'Universitas', 'Talaqqi', 'Lainnya'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setState(() => form['kategori'] = val!),
                    ),
                    const SizedBox(height: 12),
                    _inputField("Periode (Cth: 2010-2015)", form['periodeController'], icon: LucideIcons.calendar),
                    const SizedBox(height: 12),
                    _inputField("Deskripsi / Nama Kitab", form['deskripsiController'], icon: LucideIcons.alignLeft),
                    const SizedBox(height: 12),
                    _inputField("URL Website Instansi", form['websiteController'], icon: LucideIcons.link),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateDai,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text("UPDATE DATA", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
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
        labelText: label, labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true, fillColor: const Color(0xFF1E1E1E),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
