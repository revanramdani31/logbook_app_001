import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';

class LogView extends StatefulWidget {
  final String username;

  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = LogController(username: widget.username);

    // Memberikan kesempatan UI merender widget awal sebelum proses berat dimulai
    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: "log_view.dart",
      );

      // Mencoba koneksi ke MongoDB Atlas (Cloud)
      await LogHelper.writeLog(
        "UI: Menghubungi MongoService.connect()...",
        source: "log_view.dart",
      );

      // Mengaktifkan kembali koneksi dengan timeout 15 detik (lebih longgar untuk sinyal HP)
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Mengambil data log dari Cloud
      await LogHelper.writeLog(
        "UI: Memanggil controller.loadFromDisk()...",
        source: "log_view.dart",
      );

      await _controller.loadFromDisk();

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat ke Notifier.",
        source: "log_view.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: "log_view.dart",
        level: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masalah: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      // INILAH FINALLY: Apapun yang terjadi (Sukses/Gagal/Data Kosong), loading harus mati
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Colors.blue.shade100;
      case 'Urgent':
        return Colors.red.shade100;
      case 'Pribadi':
      default:
        return Colors.green.shade100;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Icons.work;
      case 'Urgent':
        return Icons.priority_high;
      case 'Pribadi':
      default:
        return Icons.note;
    }
  }

  void _showAddLogDialog() {
    final selectedCategory = ValueNotifier<String>('Pribadi');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: "Judul Catatan"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: "Isi Deskripsi"),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: selectedCategory,
                builder: (context, category, child) {
                  return DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pribadi',
                        child: Text('Pribadi'),
                      ),
                      DropdownMenuItem(
                        value: 'Pekerjaan',
                        child: Text('Pekerjaan'),
                      ),
                      DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      selectedCategory.value = value ?? 'Pribadi';
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup tanpa simpan
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Jalankan fungsi tambah di Controller
              _controller.addLog(
                _titleController.text,
                _contentController.text,
                selectedCategory.value,
              );
              // Bersihkan input dan tutup dialog
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    final selectedCategory = ValueNotifier<String>(log.category);
    _titleController.text = log.title;
    _contentController.text = log.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Judul"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: "Deskripsi"),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: selectedCategory,
                builder: (context, category, child) {
                  return DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pribadi',
                        child: Text('Pribadi'),
                      ),
                      DropdownMenuItem(
                        value: 'Pekerjaan',
                        child: Text('Pekerjaan'),
                      ),
                      DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      selectedCategory.value = value ?? 'Pribadi';
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.updateLog(
                index,
                _titleController.text,
                _contentController.text,
                selectedCategory.value,
              );
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Catatan berhasil diperbarui"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text(
                      "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingView(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Ya, Keluar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memuat data..."),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) => _controller.searchLog(value),
                    decoration: const InputDecoration(
                      labelText: "Cari Catatan...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<List<LogModel>>(
                    valueListenable: _controller.logsNotifier,
                    builder: (context, currentLogs, child) {
                      if (_isLoading) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Menghubungkan ke MongoDB Atlas..."),
                            ],
                          ),
                        );
                      }
                      if (currentLogs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 120,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Belum Ada Catatan",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Mulai catat aktivitas harianmu\ndengan menekan tombol + di bawah",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: currentLogs.length,
                        itemBuilder: (context, index) {
                          final log = currentLogs[index];
                          return Dismissible(
                            key: Key(log.date),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Hapus Catatan"),
                                      content: const Text(
                                        "Yakin ingin menghapus catatan ini?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Batal"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            "Hapus",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (direction) {
                              _controller.removeLog(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Catatan dihapus"),
                                ),
                              );
                            },
                            child: Card(
                              color: _getCategoryColor(log.category),
                              child: ListTile(
                                leading: Icon(_getCategoryIcon(log.category)),
                                title: Text(log.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.description),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            log.category,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(log.date),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showEditLogDialog(index, log),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Hapus Catatan"),
                                            content: const Text(
                                              "Yakin ingin menghapus catatan ini?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text("Batal"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _controller.removeLog(index);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Catatan berhasil dihapus",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      duration: Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  "Hapus",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog, // Panggil fungsi dialog yang baru dibuat
        child: const Icon(Icons.add),
      ),
    );
  }
}
