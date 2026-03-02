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
  
  bool _isVerified = false; 

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarController = TextEditingController();
  final _igController = TextEditingController();
  final _ytController = TextEditingController();
  final _tiktokController = TextEditingController();
  
  // FORM BERTINGKAT (NESTED)
  List<Map<String, dynamic>> _fanbaseForms = [];
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
    _nameController.clear(); _bioController.clear(); _avatarController.clear();
    _igController.clear(); _ytController.clear(); _tiktokController.clear();
    setState(() {
      _isEditMode = false; _selectedDaiId = null; _isVerified = false;
      _fanbaseForms.clear(); _sanadForms.clear();
    });
  }

  // --- TARIK DATA LAMA BUAT EDIT ---
  Future<void> _loadDaiData(String daiId) async {
    setState(() => _isFetchingData = true);
    try {
      final supabase = Supabase.instance.client;
      final daiData = await supabase.from('dais').select().eq('id', daiId).single();
      final fanbaseData = await supabase.from('dai_fanbases').select().eq('dai_id', daiId);
      // MAGIC JOIN BUAT FORM SANAD + GURU
      final sanadData = await supabase.from('dai_sanads').select('*, sanad_gurus(*)').eq('dai_id', daiId).order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _isEditMode = true; _selectedDaiId = daiId;
          _isVerified = daiData['is_verified'] == true; 
          _nameController.text = daiData['name'] ?? ''; _bioController.text = daiData['bio'] ?? '';
          _avatarController.text = daiData['avatar_url'] ?? ''; _igController.text = daiData['instagram_url'] ?? '';
          _ytController.text = daiData['youtube_channel'] ?? ''; _tiktokController.text = daiData['tiktok_url'] ?? '';

          // Mapping Fanbase
          _fanbaseForms = (fanbaseData as List).map((f) => {
            'namaController': TextEditingController(text: f['nama_akun']),
            'platform': f['platform'], 'urlController': TextEditingController(text: f['url_akun']),
          }).toList();

          // Mapping Sanad & Gurunya
          _sanadForms = (sanadData as List).map((sanad) {
            List gurus = sanad['sanad_gurus'] ?? [];
            return {
              'instansiController': TextEditingController(text: sanad['nama_instansi_guru'] ?? ''),
              'kategori': sanad['kategori'] ?? 'Pesantren',
              'periodeController': TextEditingController(text: sanad['periode'] ?? ''),
              'websiteController': TextEditingController(text: sanad['website_url'] ?? ''),
              'gurus': gurus.map((g) => {
                'namaGuruController': TextEditingController(text: g['nama_guru'] ?? ''),
                'kitabController': TextEditingController(text: g['spesialisasi_kitab'] ?? ''),
              }).toList()
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

  // --- TAMBAH / HAPUS ROW FORM ---
  void _addFanbaseForm() => setState(() => _fanbaseForms.add({'namaController': TextEditingController(), 'platform': 'instagram', 'urlController': TextEditingController()}));
  void _removeFanbaseForm(int index) => setState(() => _fanbaseForms.removeAt(index));

  void _addSanadForm() => setState(() => _sanadForms.add({
    'instansiController': TextEditingController(), 'kategori': 'Pesantren',
    'periodeController': TextEditingController(), 'websiteController': TextEditingController(),
    'gurus': <Map<String, dynamic>>[] 
  }));
  void _removeSanadForm(int index) => setState(() => _sanadForms.removeAt(index));

  void _addGuruForm(int sanadIndex) {
    setState(() {
      List gurus = _sanadForms[sanadIndex]['gurus'];
      gurus.add({'namaGuruController': TextEditingController(), 'kitabController': TextEditingController()});
    });
  }
  void _removeGuruForm(int sanadIndex, int guruIndex) {
    setState(() {
      List gurus = _sanadForms[sanadIndex]['gurus'];
      gurus.removeAt(guruIndex);
    });
  }

  // --- LOGIC SIMPAN SUPER SAKTI ---
  Future<void> _saveOrUpdateDai() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama Penceramah wajib diisi!"))); return;
    }
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String targetDaiId;

      final daiPayload = {
        'name': _nameController.text, 'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
        'avatar_url': _avatarController.text.isNotEmpty ? _avatarController.text : null,
        'instagram_url': _igController.text.isNotEmpty ? _igController.text : null,
        'youtube_channel': _ytController.text.isNotEmpty ? _ytController.text : null,
        'tiktok_url': _tiktokController.text.isNotEmpty ? _tiktokController.text : null,
        'is_verified': _isVerified, 
      };

      if (_isEditMode && _selectedDaiId != null) {
        await supabase.from('dais').update(daiPayload).eq('id', _selectedDaiId!);
        targetDaiId = _selectedDaiId!;
        await supabase.from('dai_fanbases').delete().eq('dai_id', targetDaiId);
        await supabase.from('dai_sanads').delete().eq('dai_id', targetDaiId);
      } else {
        final response = await supabase.from('dais').insert(daiPayload).select('id').single();
        targetDaiId = response['id'];
      }

      // 1. Simpan Fanbase
      if (_fanbaseForms.isNotEmpty) {
        List<Map<String, dynamic>> fanbasePayload = [];
        for (var f in _fanbaseForms) {
          if (f['namaController'].text.isNotEmpty && f['urlController'].text.isNotEmpty) {
            fanbasePayload.add({ 'dai_id': targetDaiId, 'nama_akun': f['namaController'].text, 'platform': f['platform'], 'url_akun': f['urlController'].text });
          }
        }
        if (fanbasePayload.isNotEmpty) await supabase.from('dai_fanbases').insert(fanbasePayload);
      }

      // 2. Simpan Sanad & Gurunya
      for (var s in _sanadForms) {
        if (s['instansiController'].text.isNotEmpty) {
          final sanadRes = await supabase.from('dai_sanads').insert({
            'dai_id': targetDaiId, 'nama_instansi_guru': s['instansiController'].text,
            'kategori': s['kategori'], 'periode': s['periodeController'].text.isNotEmpty ? s['periodeController'].text : null,
            'website_url': s['websiteController'].text.isNotEmpty ? s['websiteController'].text : null,
          }).select('id').single();
          
          final sanadId = sanadRes['id'];

          List gurus = s['gurus'];
          List<Map<String, dynamic>> guruPayload = [];
          for (var g in gurus) {
            if (g['namaGuruController'].text.isNotEmpty) {
              guruPayload.add({
                'sanad_id': sanadId, 'nama_guru': g['namaGuruController'].text,
                'spesialisasi_kitab': g['kitabController'].text.isNotEmpty ? g['kitabController'].text : null
              });
            }
          }
          if (guruPayload.isNotEmpty) await supabase.from('sanad_gurus').insert(guruPayload);
        }
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
            // --- PEMILIHAN AKSI ---
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilih Aksi", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: _selectedDaiId, dropdownColor: const Color(0xFF1E1E1E), style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text("[+] Tambah Dai Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
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
              // --- 1. PROFIL PENCERAMAH ---
              Text("1. Profil Penceramah", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _inputField("Nama Penceramah *", _nameController, icon: LucideIcons.user), const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: Row(children: [const Icon(Icons.verified, color: Colors.blueAccent, size: 20), const SizedBox(width: 8), Text("Centang Biru", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14))]),
                  value: _isVerified, activeColor: Colors.blueAccent, onChanged: (val) => setState(() => _isVerified = val),
                ),
              ),
              const SizedBox(height: 12),
              _inputField("URL Foto (Avatar)", _avatarController, icon: LucideIcons.image), const SizedBox(height: 12),
              _inputField("Bio Singkat", _bioController, maxLines: 3), const SizedBox(height: 12),
              _inputField("Link Instagram Resmi", _igController, icon: LucideIcons.instagram), const SizedBox(height: 12),
              _inputField("Link YouTube Resmi", _ytController, icon: LucideIcons.youtube), const SizedBox(height: 12),
              _inputField("Link TikTok Resmi", _tiktokController, icon: Icons.tiktok),
              const SizedBox(height: 30), const Divider(color: Colors.white24), const SizedBox(height: 20),

              // --- 2. AKUN FANBASE ---
              // 🔥 Header Tanpa Tombol Plus 🔥
              Text("2. Akun Fanbase / Clipper", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              ..._fanbaseForms.asMap().entries.map((entry) {
                int index = entry.key; Map<String, dynamic> f = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("Fanbase #${index + 1}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), InkWell(onTap: () => _removeFanbaseForm(index), child: const Icon(Icons.delete, color: Colors.redAccent, size: 18))],
                      ),
                      const SizedBox(height: 12), _inputField("Nama Akun Fanbase *", f['namaController']), const SizedBox(height: 8),
                      DropdownButtonFormField<String>(value: f['platform'], dropdownColor: const Color(0xFF2C2C2C), style: GoogleFonts.poppins(color: Colors.white), decoration: _dropdownDeco("Platform"), items: ['instagram', 'youtube', 'tiktok'].map((val) => DropdownMenuItem(value: val, child: Text(val.toUpperCase()))).toList(), onChanged: (val) => setState(() => f['platform'] = val!)),
                      const SizedBox(height: 8), _inputField("URL Link Akun *", f['urlController']),
                    ],
                  ),
                );
              }),
              
              // 🔥 TOMBOL PLUS PINDAH KE BAWAH SINI 🔥
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addFanbaseForm, icon: const Icon(Icons.add, color: Colors.blueAccent, size: 18), label: Text("Tambah Akun Fanbase", style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 13)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),

              const SizedBox(height: 30), const Divider(color: Colors.white24), const SizedBox(height: 20),

              // --- 3. SANAD TREE ---
              // 🔥 Header Tanpa Tombol Plus 🔥
              Text("3. Otoritas Keilmuan (Sanad)", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              ..._sanadForms.asMap().entries.map((entry) {
                int sIndex = entry.key; Map<String, dynamic> s = entry.value;
                List gurus = s['gurus'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2962FF).withOpacity(0.5))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("Jalur Sanad #${sIndex + 1}", style: GoogleFonts.poppins(color: const Color(0xFF2962FF), fontWeight: FontWeight.bold)), InkWell(onTap: () => _removeSanadForm(sIndex), child: const Icon(Icons.delete, color: Colors.redAccent, size: 20))],
                      ),
                      const SizedBox(height: 12), _inputField("Nama Instansi / Pondok *", s['instansiController'], icon: LucideIcons.building), const SizedBox(height: 8),
                      DropdownButtonFormField<String>(value: s['kategori'], dropdownColor: const Color(0xFF2C2C2C), style: GoogleFonts.poppins(color: Colors.white), decoration: _dropdownDeco("Kategori"), items: ['Pesantren', 'Universitas', 'Talaqqi', 'Keluarga'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) => setState(() => s['kategori'] = val!)),
                      const SizedBox(height: 8), _inputField("Periode (Cth: 2010-2015)", s['periodeController'], icon: LucideIcons.calendar), const SizedBox(height: 8),
                      _inputField("URL Website Instansi (Tabayyun)", s['websiteController'], icon: LucideIcons.link),
                      
                      // -- NESTED GURU FORM --
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Daftar Guru/Kiai di sini:", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (gurus.isEmpty) Text("Belum ada guru dicatat.", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            ...gurus.asMap().entries.map((gEntry) {
                              int gIndex = gEntry.key; Map<String, dynamic> g = gEntry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12), // Kasih jarak antar guru
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _inputField("Nama Kiai/Guru *", g['namaGuruController']), const SizedBox(height: 4),
                                          _inputField("Fokus Kitab/Ilmu", g['kitabController']),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(onPressed: () => _removeGuruForm(sIndex, gIndex), icon: const Icon(Icons.close, color: Colors.redAccent))
                                  ],
                                ),
                              );
                            }),
                            
                            // 🔥 Tombol Tambah Guru Pindah Ke Bawah List Guru 🔥
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () => _addGuruForm(sIndex), icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent), label: Text("Tambah Guru Baru", style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12)),
                                style: TextButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.1), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),

              // 🔥 TOMBOL PLUS SANAD PINDAH KE BAWAH SINI 🔥
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addSanadForm, icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent), label: Text("Tambah Jalur Sanad Baru", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.blueAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrUpdateDai,
                  style: ElevatedButton.styleFrom(backgroundColor: _isEditMode ? Colors.amber[700] : const Color(0xFF2962FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditMode ? "UPDATE SEMUA DATA" : "SIMPAN DAI BARU", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      controller: controller, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: maxLines,
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12), filled: true, fillColor: const Color(0xFF1E1E1E), prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 18) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
    );
  }

  InputDecoration _dropdownDeco(String label) => InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12), filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none));
}