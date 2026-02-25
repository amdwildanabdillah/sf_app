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
  List<Map<String, dynamic>> _daiList = [];
  String? _selectedDaiId; 
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isFetchingData = false;
  
  // --- STATE BARU: CENTANG BIRU ---
  bool _isVerified = false; 

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarController = TextEditingController();
  final _igController = TextEditingController();
  final _ytController = TextEditingController();
  final _tiktokController = TextEditingController();
  
  List<Map<String, dynamic>> _sanadForms = [];

  @override
  void initState() {
    super.initState();
    _fetchDaiList(); 
  }

  Future<void> _fetchDaiList() async {
    try {
      final response = await Supabase.instance.client.from('dais').select('id, name').order('name', ascending: true);
      if (mounted) setState(() => _daiList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Gagal load daftar dai: $e");
    }
  }

  void _clearForm() {
    _nameController.clear();
    _bioController.clear();
    _avatarController.clear();
    _igController.clear();
    _ytController.clear();
    _tiktokController.clear();
    _sanadForms.clear();
    setState(() {
      _isEditMode = false;
      _selectedDaiId = null;
      _isVerified = false; // Reset centang biru
    });
  }

  Future<void> _loadDaiData(String daiId) async {
    setState(() => _isFetchingData = true);
    try {
      final daiData = await Supabase.instance.client.from('dais').select().eq('id', daiId).single();
      final sanadData = await Supabase.instance.client.from('dai_sanads').select().eq('dai_id', daiId).order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _isEditMode = true;
          _selectedDaiId = daiId;
          
          // --- TARIK STATUS CENTANG BIRU DARI DB ---
          _isVerified = daiData['is_verified'] == true; 

          _nameController.text = daiData['name'] ?? '';
          _bioController.text = daiData['bio'] ?? '';
          _avatarController.text = daiData['avatar_url'] ?? '';
          _igController.text = daiData['instagram_url'] ?? '';
          _ytController.text = daiData['youtube_channel'] ?? '';
          _tiktokController.text = daiData['tiktok_url'] ?? '';

          _sanadForms = (sanadData as List).map((sanad) {
            return {
              'namaController': TextEditingController(text: sanad['nama_instansi_guru'] ?? ''),
              'kategori': sanad['kategori'] ?? 'Pesantren',
              'periodeController': TextEditingController(text: sanad['periode'] ?? ''),
              'deskripsiController': TextEditingController(text: sanad['deskripsi'] ?? ''),
              'websiteController': TextEditingController(text: sanad['website_url'] ?? ''),
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal tarik data: $e")));
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  void _addSanadForm() {
    setState(() => _sanadForms.add({
      'namaController': TextEditingController(), 'kategori': 'Pesantren',
      'periodeController': TextEditingController(), 'deskripsiController': TextEditingController(),
      'websiteController': TextEditingController(),
    }));
  }

  void _removeSanadForm(int index) => setState(() => _sanadForms.removeAt(index));

  Future<void> _saveOrUpdateDai() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama Penceramah wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String targetDaiId;

      final daiPayload = {
        'name': _nameController.text,
        'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
        'avatar_url': _avatarController.text.isNotEmpty ? _avatarController.text : null,
        'instagram_url': _igController.text.isNotEmpty ? _igController.text : null,
        'youtube_channel': _ytController.text.isNotEmpty ? _ytController.text : null,
        'tiktok_url': _tiktokController.text.isNotEmpty ? _tiktokController.text : null,
        'is_verified': _isVerified, // --- SIMPAN STATUS CENTANG BIRU KE DB ---
      };

      if (_isEditMode && _selectedDaiId != null) {
        await Supabase.instance.client.from('dais').update(daiPayload).eq('id', _selectedDaiId!);
        targetDaiId = _selectedDaiId!;
        await Supabase.instance.client.from('dai_sanads').delete().eq('dai_id', targetDaiId);
      } else {
        final response = await Supabase.instance.client.from('dais').insert(daiPayload).select('id').single();
        targetDaiId = response['id'];
      }

      if (_sanadForms.isNotEmpty) {
        List<Map<String, dynamic>> sanadDataToInsert = [];
        for (var form in _sanadForms) {
          if (form['namaController'].text.isNotEmpty) {
            sanadDataToInsert.add({
              'dai_id': targetDaiId, 'nama_instansi_guru': form['namaController'].text,
              'kategori': form['kategori'], 'periode': form['periodeController'].text.isNotEmpty ? form['periodeController'].text : null,
              'deskripsi': form['deskripsiController'].text.isNotEmpty ? form['deskripsiController'].text : null,
              'website_url': form['websiteController'].text.isNotEmpty ? form['websiteController'].text : null,
            });
          }
        }
        if (sanadDataToInsert.isNotEmpty) await Supabase.instance.client.from('dai_sanads').insert(sanadDataToInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditMode ? "Data Berhasil Diupdate!" : "Dai Baru Berhasil Ditambah!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("Kelola Database Dai", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)), leading: const BackButton(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilih Aksi", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: _selectedDaiId, dropdownColor: const Color(0xFF1E1E1E), style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 20)),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text("✨ [+] Tambah Dai Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                      ..._daiList.map((dai) => DropdownMenuItem<String?>(value: dai['id'], child: Text(dai['name'], style: GoogleFonts.poppins(color: Colors.white)))),
                    ],
                    onChanged: (val) { if (val == null) _clearForm(); else _loadDaiData(val); },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            if (_isFetchingData) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.blueAccent)))
            else ...[
              Text("1. Profil Penceramah", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _inputField("Nama Penceramah *", _nameController, icon: LucideIcons.user),
              const SizedBox(height: 12),
              
              // --- SAKLAR CENTANG BIRU ---
              Container(
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      Text("Centang Biru", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  value: _isVerified,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => setState(() => _isVerified = val),
                ),
              ),
              
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
                  IconButton(onPressed: _addSanadForm, icon: const Icon(Icons.add_circle, color: Colors.blueAccent))
                ],
              ),
              const SizedBox(height: 16),

              ..._sanadForms.asMap().entries.map((entry) {
                int index = entry.key; Map<String, dynamic> form = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Riwayat #${index + 1}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          InkWell(onTap: () => _removeSanadForm(index), child: const Icon(Icons.delete, color: Colors.redAccent, size: 20))
                        ],
                      ),
                      const SizedBox(height: 12), _inputField("Nama Guru / Instansi *", form['namaController'], icon: LucideIcons.bookOpen),
                      const SizedBox(height: 12), DropdownButtonFormField<String>(value: form['kategori'], dropdownColor: const Color(0xFF2C2C2C), style: GoogleFonts.poppins(color: Colors.white), decoration: InputDecoration(labelText: "Kategori", labelStyle: TextStyle(color: Colors.grey[400]), filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: ['Pesantren', 'Universitas', 'Talaqqi', 'Lainnya'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) => setState(() => form['kategori'] = val!)),
                      const SizedBox(height: 12), _inputField("Periode (Cth: 2010-2015)", form['periodeController'], icon: LucideIcons.calendar),
                      const SizedBox(height: 12), _inputField("Deskripsi / Nama Kitab", form['deskripsiController'], icon: LucideIcons.alignLeft),
                      const SizedBox(height: 12), _inputField("URL Website Instansi", form['websiteController'], icon: LucideIcons.link),
                    ],
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrUpdateDai,
                  style: ElevatedButton.styleFrom(backgroundColor: _isEditMode ? Colors.amber[700] : const Color(0xFF2962FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditMode ? "UPDATE DATA DAI" : "SIMPAN DAI BARU", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ]
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, {IconData? icon, int maxLines = 1}) {
    return TextField(
      controller: controller, style: const TextStyle(color: Colors.white), maxLines: maxLines,
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.grey[400]), filled: true, fillColor: const Color(0xFF1E1E1E), prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }
}