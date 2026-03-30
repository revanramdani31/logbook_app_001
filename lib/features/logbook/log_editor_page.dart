import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedVisibility;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _selectedVisibility = widget.log?.visibility ?? 'Public';
    _selectedCategory = widget.log?.category ?? 'Software';

    // Debug: Cek data user
    print('DEBUG Editor - User ID: ${widget.currentUser['uid']}');
    print('DEBUG Editor - Team ID: ${widget.currentUser['teamId']}');

    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() async {
    // Validasi input
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (widget.log == null) {
        // Tambah Baru
        await widget.controller.addLog(
          _titleController.text.trim(),
          _descController.text.trim(),
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
          visibility: _selectedVisibility,
          category: _selectedCategory,
        );
      } else {
        // Update
        await widget.controller.updateLog(
          widget.log!,
          _titleController.text.trim(),
          _descController.text.trim(),
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
          currentUserId: widget.currentUser['uid'],
          currentUserRole: widget.currentUser['role'],
          visibility: _selectedVisibility,
          category: _selectedCategory,
        );
      }

      // Berhasil, kembali ke halaman sebelumnya
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Tangani error
      print('ERROR Save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  // Dropdown Visibility
                  DropdownButtonFormField<String>(
                    value: _selectedVisibility,
                    decoration: const InputDecoration(
                      labelText: "Visibilitas",
                      prefixIcon: Icon(Icons.visibility),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Public',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Public'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Private',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Private'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVisibility = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Dropdown Kategori Teknis
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori Teknis",
                      prefixIcon: Icon(Icons.engineering),
                      helperText: "Pilih bidang teknis untuk log ini",
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Mechanical',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.precision_manufacturing,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text('Mechanical'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Electronic',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.electrical_services,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text('Electronic'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Software',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.computer,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text('Software'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Integration',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hub, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Integration'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Testing',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Testing'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Documentation',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description,
                              size: 16,
                              color: Colors.brown,
                            ),
                            SizedBox(width: 8),
                            Text('Documentation'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: '''Tulis laporan dengan format Markdown...
Contoh format yang bisa digunakan:
**tebal** untuk teks tebal
*miring* untuk teks miring
# Judul Besar
## Judul Sedang
### Judul Kecil
- Poin 1
- Poin 2
1. Nomor satu
2. Nomor dua
[link](https://url.com) untuk link
`kode` untuk kode inline''',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview dengan MarkdownBody
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                data: _descController.text.isEmpty
                    ? '_Belum ada konten untuk ditampilkan..._'
                    : _descController.text,
                selectable: true, // User bisa select & copy text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
