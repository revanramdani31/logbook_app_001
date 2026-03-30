import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/features/logbook/helpers/log_category_ui_helper.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/widgets/empty_state_widget.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser;

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  late final TextEditingController _searchController;
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    print('DEBUG LogView - Init with user: ${widget.currentUser['username']}');
    print('DEBUG LogView - Team ID: ${widget.currentUser['teamId']}');

    _controller = LogController(username: widget.currentUser['username']);
    _searchController = TextEditingController();

    // Listener untuk search real-time
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.toLowerCase();
    });

    // Load logs
    _controller.loadLogs(widget.currentUser['teamId']).then((_) {
      print('DEBUG LogView - LoadLogs completed');
      print(
        'DEBUG LogView - Total logs in notifier: ${_controller.logsNotifier.value.length}',
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  // Widget untuk menampilkan list logs atau empty state
  Widget _buildLogsList(
    List<LogModel> filteredLogs,
    List<LogModel> allLogs,
    String searchQuery,
  ) {
    // Jika data kosong, tampilkan Empty State
    if (filteredLogs.isEmpty) {
      // Empty state untuk hasil pencarian
      if (searchQuery.isNotEmpty) {
        return SearchEmptyStateWidget(searchQuery: searchQuery);
      }

      // Empty state untuk tidak ada data sama sekali
      return EmptyStateWidget(
        title: "Belum ada aktivitas hari ini? 📝",
        subtitle:
            "Mulai catat kemajuan proyek Anda!\nSetiap langkah kecil adalah progress yang berarti.",
        buttonText: "Buat Catatan Pertama",
        onButtonPressed: () => _goToEditor(),
        animationUrl:
            'https://lottie.host/4f82ce6f-6c96-4ed9-b21c-3d2a5e8d0e8f/JT7KSdPRAZ.json',
        fallbackIcon: Icons.note_alt_outlined,
      );
    }

    // Tampilkan ListView
    return ListView.builder(
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        final bool isOwner = log.authorId == widget.currentUser['uid'];
        final userInfo = LoginController.getPublicUserInfo(log.authorId);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris pertama: Title dan Sync Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Tooltip(
                      message: log.id != null
                          ? 'Tersinkron ke Cloud'
                          : 'Belum tersinkron (data lokal)',
                      child: Icon(
                        log.id != null
                            ? Icons.cloud_done
                            : Icons.cloud_upload_outlined,
                        color: log.id != null ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Deskripsi dengan Markdown Support
                Container(
                  constraints: const BoxConstraints(maxHeight: 40), // ~2 lines
                  child: MarkdownBody(
                    data: log.description,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      strong: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    shrinkWrap: true,
                    fitContent: true,
                  ),
                ),
                const SizedBox(height: 12),
                // Baris info: Kategori, Pembuat, Visibility
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Kategori
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: LogCategoryUiHelper.getCategoryColor(
                          log.category,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: LogCategoryUiHelper.getCategoryColor(
                            log.category,
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LogCategoryUiHelper.getCategoryIcon(log.category),
                            size: 14,
                            color: LogCategoryUiHelper.getCategoryColor(
                              log.category,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: LogCategoryUiHelper.getCategoryColor(
                                log.category,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pembuat dan Jabatan
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${userInfo['fullName']} (${userInfo['role']})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Visibility
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          log.visibility == 'Private'
                              ? Icons.lock
                              : Icons.public,
                          size: 14,
                          color: log.visibility == 'Private'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.visibility,
                          style: TextStyle(
                            fontSize: 11,
                            color: log.visibility == 'Private'
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Tombol aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // GATEKEEPER: Tombol Edit
                    if (AccessControlService.canPerform(
                      widget.currentUser['role'],
                      AccessControlService.actionUpdate,
                      isOwner: isOwner,
                    ))
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: () => _goToEditor(log: log),
                      ),

                    // GATEKEEPER: Tombol Delete
                    if (AccessControlService.canPerform(
                      widget.currentUser['role'],
                      AccessControlService.actionDelete,
                      isOwner: isOwner,
                    ))
                      TextButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => _controller.removeLog(
                          log,
                          currentUserId: widget.currentUser['uid'],
                          currentUserRole: widget.currentUser['role'],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navigasi ke Halaman Editor (Gantikan Dialog Lama)
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Logbook: ${widget.currentUser['username']} | Role: ${widget.currentUser['role']}",
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadLogs(widget.currentUser['teamId']),
          ),
          // --- TOMBOL LOGOUT BARU ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
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
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Cari berdasarkan judul, deskripsi, kategori, atau nama...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, query, child) {
                    if (query.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // List Logs
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {

                final visibleLogs = _controller.filterVisibleLogs(
                  currentLogs,
                  widget.currentUser['uid'],
                );


                // Gunakan ValueListenableBuilder untuk search query
                return ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, searchQuery, child) {
                    final filteredLogs = _controller.filterLogsByQuery(
                      visibleLogs,
                      searchQuery,
                      LoginController.getPublicUserInfo,
                    );

                    // Info hasil pencarian
                    if (searchQuery.isNotEmpty) {
                      print('Search query: "$searchQuery"');
                      print('Filtered logs: ${filteredLogs.length}');
                    }

                    return Column(
                      children: [
                        // Info hasil pencarian
                        if (searchQuery.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.blue.shade50,
                            child: Text(
                              'Ditemukan ${filteredLogs.length} hasil untuk "$searchQuery"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        // List atau Empty State
                        Expanded(
                          child: _buildLogsList(
                            filteredLogs,
                            currentLogs,
                            searchQuery,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
