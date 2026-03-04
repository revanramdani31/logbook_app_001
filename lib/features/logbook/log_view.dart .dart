import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _searchController = TextEditingController();

  // FutureBuilder: View langsung memanggil Service
  late Future<List<LogModel>> _logsFuture;

  // Search query state
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller = LogController(username: widget.username);
    _loadLogs(); // Inisialisasi Future untuk FutureBuilder
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter logs berdasarkan search query
  List<LogModel> _filterLogs(List<LogModel> logs) {
    if (_searchQuery.isEmpty) {
      return logs;
    }

    return logs.where((log) {
      final query = _searchQuery.toLowerCase();
      return log.title.toLowerCase().contains(query) ||
          log.description.toLowerCase().contains(query) ||
          log.category.toLowerCase().contains(query);
    }).toList();
  }

  // Method untuk load/refresh data dari MongoDB via Service
  void _loadLogs() {
    setState(() {
      _logsFuture = _fetchLogsFromMongo();
    });
  }

  Future<void> _refreshData() async {
    await LogHelper.writeLog(
      "UI: Pull-to-Refresh triggered by user",
      source: "log_view.dart",
    );

    setState(() {
      _logsFuture = _fetchLogsFromMongo();
    });

    // Wait untuk Future complete
    await _logsFuture;
  }

  Future<List<LogModel>> _fetchLogsFromMongo() async {
    try {
      await LogHelper.writeLog(
        "UI: Memulai fetch data via FutureBuilder...",
        source: "log_view.dart",
      );

      // Pastikan koneksi aktif terlebih dahulu
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "TIMEOUT", // Simplified error marker
        ),
      );

      // View langsung memanggil MongoService.getLogs()
      final logs = await MongoService().getLogs();

      await LogHelper.writeLog(
        "UI: Berhasil fetch ${logs.length} logs dari MongoDB",
        source: "log_view.dart",
      );

      return logs;
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error fetch logs - $e",
        source: "log_view.dart",
        level: 1,
      );
      rethrow; // FutureBuilder akan handle error ini
    }
  }

  // Connection Guard: Deteksi tipe error dan return pesan ramah
  Map<String, dynamic> _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Deteksi berbagai jenis koneksi error
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return {
        'icon': Icons.wifi_off,
        'title': 'Koneksi Terputus',
        'message':
            'Server tidak merespons. Periksa:\n'
            '• Koneksi internet Anda\n'
            '• Sinyal WiFi/Data seluler\n'
            '• IP Whitelist MongoDB (0.0.0.0/0)',
        'color': Colors.orange,
      };
    }

    if (errorStr.contains('socketexception') ||
        errorStr.contains('network') ||
        errorStr.contains('no internet')) {
      return {
        'icon': Icons.signal_wifi_off,
        'title': 'Tidak Ada Koneksi Internet',
        'message':
            'Aplikasi tidak dapat terhubung ke internet.\n'
            'Periksa koneksi WiFi atau data seluler Anda.',
        'color': Colors.red,
      };
    }

    if (errorStr.contains('connection refused') ||
        errorStr.contains('failed host lookup')) {
      return {
        'icon': Icons.cloud_off,
        'title': 'Server Tidak Dapat Dijangkau',
        'message':
            'MongoDB Atlas tidak dapat dihubungi.\n'
            'Periksa konfigurasi database Anda.',
        'color': Colors.red,
      };
    }

    if (errorStr.contains('authentication') ||
        errorStr.contains('credentials')) {
      return {
        'icon': Icons.lock_outline,
        'title': 'Autentikasi Gagal',
        'message':
            'Username atau password database salah.\n'
            'Periksa konfigurasi MONGODB_URI.',
        'color': Colors.red,
      };
    }

    // Default error message
    return {
      'icon': Icons.error_outline,
      'title': 'Terjadi Kesalahan',
      'message':
          'Aplikasi mengalami masalah saat mengakses database.\n\n'
          'Detail: ${error.toString()}',
      'color': Colors.red,
    };
  }

  // Timestamp Formatting: Format waktu dengan intl - Lokal Indonesia
  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(dt);

      // Relative Time untuk waktu yang baru saja terjadi
      if (difference.inSeconds < 60) {
        return "Baru saja";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} menit yang lalu";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} jam yang lalu";
      } else if (difference.inDays == 1) {
        return "Kemarin, ${DateFormat('HH:mm').format(dt)}";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} hari yang lalu";
      } else if (difference.inDays < 30) {
        // Format: "Senin, 20 Jan"
        return DateFormat('EEEE, d MMM', 'id_ID').format(dt);
      } else {
        // Format lengkap: "25 Jan 2026, 14:30"
        return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
      }
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
            onPressed: () async {
              // Jalankan fungsi tambah di Controller
              await _controller.addLog(
                _titleController.text,
                _contentController.text,
                selectedCategory.value,
              );
              // Bersihkan input dan tutup dialog
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);

              // Refresh data dari MongoDB via FutureBuilder
              _loadLogs();
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
            onPressed: () async {
              await _controller.updateLog(
                index,
                _titleController.text,
                _contentController.text,
                selectedCategory.value,
                logId: log.id, // Pass log ID
              );
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);

              // Refresh data dari MongoDB via FutureBuilder
              _loadLogs();

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
      body: FutureBuilder<List<LogModel>>(
        future: _logsFuture, // View memanggil Service via Future ini
        builder: (context, snapshot) {
          // 1. State: Loading (menunggu data)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memuat data dari MongoDB..."),
                ],
              ),
            );
          }

          // 2. State: Error - Offline Mode Warning dengan pesan ramah
          if (snapshot.hasError) {
            final errorInfo = _getErrorMessage(snapshot.error);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon dengan warna dinamis
                    Icon(
                      errorInfo['icon'] as IconData,
                      size: 100,
                      color: errorInfo['color'] as Color,
                    ),
                    const SizedBox(height: 24),

                    // Title error
                    Text(
                      errorInfo['title'] as String,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: errorInfo['color'] as Color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Pesan detail dengan background card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (errorInfo['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (errorInfo['color'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        errorInfo['message'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Coba Lagi
                    ElevatedButton.icon(
                      onPressed: _loadLogs,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Coba Lagi"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: errorInfo['color'] as Color,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Hint tambahan
                    const SizedBox(height: 16),
                    Text(
                      "💡 Tip: Pastikan Anda terhubung ke internet",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. State: Success - Data sudah tersedia
          final allLogs = snapshot.data ?? [];
          final logs = _filterLogs(allLogs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Cari Catatan...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: allLogs.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 250,
                            child: Center(
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
                                  const SizedBox(height: 16),
                                  Text(
                                    "⬇️ Tarik ke bawah untuk refresh",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : logs.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 250,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 100,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Tidak ada hasil",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Coba kata kunci lain",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            // Find original index in allLogs using ID
                            final originalIndex = allLogs.indexWhere(
                              (l) =>
                                  l.id?.toHexString() == log.id?.toHexString(),
                            );
                            return Dismissible(
                              key: Key(log.id?.toHexString() ?? log.date),
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (direction) async {
                                await _controller.removeLog(
                                  originalIndex,
                                  logId: log.id, // Pass log ID
                                );
                                _loadLogs(); // Refresh data dari MongoDB
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                          // Timestamp dengan icon
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(log.date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
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
                                        onPressed: () => _showEditLogDialog(
                                          originalIndex,
                                          log,
                                        ),
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
                                              title: const Text(
                                                "Hapus Catatan",
                                              ),
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
                                                  onPressed: () async {
                                                    await _controller.removeLog(
                                                      originalIndex,
                                                      logId:
                                                          log.id, // Pass log ID
                                                    );
                                                    Navigator.pop(context);
                                                    _loadLogs(); // Refresh data dari MongoDB
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
                        ), // End of ListView.builder
                      ), // End of RefreshIndicator
              ),
            ],
          );
        },
      ), // End of FutureBuilder
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog, // Panggil fungsi dialog yang baru dibuat
        child: const Icon(Icons.add),
      ),
    );
  }
}
