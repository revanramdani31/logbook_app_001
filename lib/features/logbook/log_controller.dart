import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/policies/access_policy.dart';

class LogController {
  final String username;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final _myBox = Hive.box<LogModel>('offline_logs');
  bool _isAutoSyncRunning = false;
  final Set<String> _inFlightLogs =
      <String>{}; // Track logs being synced in addLog

  LogController({required this.username});

  int _findIndexInList(List<LogModel> logs, LogModel target) {
    if (target.id != null) {
      final byId = logs.indexWhere((log) => log.id == target.id);
      if (byId != -1) return byId;
    }

    return logs.indexWhere(
      (log) =>
          log.title == target.title &&
          log.description == target.description &&
          log.date == target.date &&
          log.authorId == target.authorId &&
          log.teamId == target.teamId &&
          log.visibility == target.visibility &&
          log.category == target.category,
    );
  }

  int _findIndexInHive(LogModel target) {
    if (target.id != null) {
      for (var i = 0; i < _myBox.length; i++) {
        final log = _myBox.getAt(i);
        if (log?.id == target.id) return i;
      }
    }

    for (var i = 0; i < _myBox.length; i++) {
      final log = _myBox.getAt(i);
      if (log == null) continue;

      if (log.title == target.title &&
          log.description == target.description &&
          log.date == target.date &&
          log.authorId == target.authorId &&
          log.teamId == target.teamId &&
          log.visibility == target.visibility &&
          log.category == target.category) {
        return i;
      }
    }

    return -1;
  }

  List<LogModel> filterVisibleLogs(List<LogModel> logs, String currentUserId) {
    return logs.where((log) {
      final isOwner = log.authorId == currentUserId;
      return AccessPolicy.canViewLog(log.visibility, isOwner);
    }).toList();
  }

  List<LogModel> filterLogsByQuery(
    List<LogModel> logs,
    String query,
    Map<String, String> Function(String authorId) getPublicUserInfo,
  ) {
    if (query.isEmpty) return logs;

    return logs.where((log) {
      final titleMatch = log.title.toLowerCase().contains(query);
      final descMatch = log.description.toLowerCase().contains(query);
      final categoryMatch = log.category.toLowerCase().contains(query);
      final authorInfo = getPublicUserInfo(log.authorId);
      final authorMatch = (authorInfo['fullName'] ?? '').toLowerCase().contains(
        query,
      );

      return titleMatch || descMatch || categoryMatch || authorMatch;
    }).toList();
  }

  void _enforceModifyPermission(
    LogModel targetLog,
    String currentUserId,
    String currentUserRole,
    String action,
  ) {
    final isOwner = targetLog.authorId == currentUserId;
    final canModify = AccessControlService.canPerform(
      currentUserRole,
      action,
      isOwner: isOwner,
    );

    if (!canModify) {
      throw Exception('Akses ditolak: Anda tidak memiliki izin untuk aksi ini');
    }
  }

  Future<int> _autoSyncPendingLogs(String teamId) async {
    if (_isAutoSyncRunning) return 0;

    _isAutoSyncRunning = true;
    var syncedCount = 0;

    try {
      // Snapshot loop agar index tidak kacau saat concurrent modification
      final pendingLogs = <int, LogModel>{};
      for (var i = 0; i < _myBox.length; i++) {
        final log = _myBox.getAt(i);
        if (log == null) continue;
        if (log.teamId != teamId) continue;

        final logId = log.id;
        if (logId != null && logId.isNotEmpty) continue;

        // Skip jika log sedang dalam proses addLog
        final logKey =
            '${log.title}|${log.description}|${log.authorId}|${log.teamId}';
        if (_inFlightLogs.contains(logKey)) {
          print(
            'DEBUG _autoSyncPendingLogs - SKIP pending (in-flight): title="${log.title}"',
          );
          continue;
        }

        pendingLogs[i] = log; // Snapshot before upload
      }

      print(
        'DEBUG _autoSyncPendingLogs - Found ${pendingLogs.length} pending logs to sync for team $teamId',
      );

      for (var entry in pendingLogs.entries) {
        final i = entry.key;
        final log = entry.value;

        try {
          final inserted = await MongoService().insertLog(log);

          if (inserted.id == null || inserted.id!.isEmpty) {
            print(
              'DEBUG _autoSyncPendingLogs - WARNING: insertLog returned log with null/empty id for "${log.title}"',
            );
            continue;
          }

          final syncedLog = LogModel(
            id: inserted.id,
            title: log.title,
            description: log.description,
            date: log.date,
            authorId: log.authorId,
            teamId: log.teamId,
            visibility: log.visibility,
            category: log.category,
          );

          // Verifikasi sebelum putAt
          final hiveLogNow = _myBox.getAt(i);
          if (hiveLogNow?.teamId != teamId) {
            print(
              'DEBUG _autoSyncPendingLogs - SKIP putAt: Hive[{$i}] teamId changed or deleted',
            );
            continue;
          }

          await _myBox.putAt(i, syncedLog);
          syncedCount++;

          print(
            'DEBUG _autoSyncPendingLogs - Synced index $i: "${log.title}" -> got id: ${inserted.id}',
          );
        } catch (e) {
          print(
            'DEBUG _autoSyncPendingLogs - Failed to sync "${log.title}": $e',
          );
        }
      }
    } finally {
      _isAutoSyncRunning = false;
    }

    print(
      'DEBUG _autoSyncPendingLogs - Completed: synced $syncedCount items for team $teamId',
    );

    return syncedCount;
  }

  Future<void> loadLogs(String teamId) async {
    // 🔒 SELALU load dari Hive dulu (offline-first)
    // Filter berdasarkan teamId agar hanya muncul data tim sendiri
    final localData = _myBox.values
        .where((log) => log.teamId == teamId)
        .toList();
    logsNotifier.value = localData;

    print('DEBUG loadLogs - Requesting teamId: $teamId');
    print('DEBUG loadLogs - Total Hive items: ${_myBox.length}');
    print('DEBUG loadLogs - Filtered local data count: ${localData.length}');

    // 🌐 Coba sync dari Atlas jika online
    try {
      final autoSyncedCount = await _autoSyncPendingLogs(teamId);
      if (autoSyncedCount > 0) {
        print('DEBUG loadLogs - Auto-synced pending logs: $autoSyncedCount');
        await LogHelper.writeLog(
          "SYNC: Auto-upload pending lokal berhasil ($autoSyncedCount items)",
          level: 2,
        );
      }

      final refreshedLocalData = _myBox.values
          .where((log) => log.teamId == teamId)
          .toList();

      final cloudData = await MongoService().getLogs(teamId);

      print('DEBUG loadLogs - Cloud data count: ${cloudData.length}');

      if (cloudData.isNotEmpty) {
        final cloudIds = cloudData
            .where((log) => log.id != null && log.id!.isNotEmpty)
            .map((log) => log.id!)
            .toSet();

        print(
          'DEBUG loadLogs - Cloud IDs extracted: ${cloudIds.length} items: $cloudIds',
        );

        final pendingOrLocalOnly = refreshedLocalData.where((log) {
          final id = log.id;
          final isPending = id == null || id.isEmpty;
          final isLocalOnly = !isPending && !cloudIds.contains(id);
          final include = isPending || isLocalOnly;

          if (include) {
            print(
              'DEBUG loadLogs - Include in merge: title="${log.title}", id=$id, pending=$isPending, localOnly=$isLocalOnly',
            );
          }

          return include;
        }).toList();

        print(
          'DEBUG loadLogs - Filtered pending/local-only: ${pendingOrLocalOnly.length} items',
        );

        final mergedData = <LogModel>[...cloudData, ...pendingOrLocalOnly];

        print(
          'DEBUG loadLogs - Merged final: ${mergedData.length} items (cloud ${cloudData.length} + pending/local-only ${pendingOrLocalOnly.length})',
        );

        final keysToDelete = <dynamic>[];
        for (var i = 0; i < _myBox.length; i++) {
          final log = _myBox.getAt(i);
          if (log?.teamId == teamId) {
            keysToDelete.add(i);
          }
        }

        // Hapus dari belakang agar index tidak berubah
        for (var i = keysToDelete.length - 1; i >= 0; i--) {
          await _myBox.deleteAt(keysToDelete[i]);
        }

        print(
          'DEBUG loadLogs - Deleted ${keysToDelete.length} old items for team $teamId',
        );

        // 2. Tulis kembali hasil merge (cloud + pending lokal)
        await _myBox.addAll(mergedData);

        print(
          'DEBUG loadLogs - Merged data count: ${mergedData.length} '
          '(cloud: ${cloudData.length}, pending/local-only: ${pendingOrLocalOnly.length})',
        );

        logsNotifier.value = mergedData;
        await LogHelper.writeLog(
          "SYNC: Data cloud diperbarui (${cloudData.length}) + pending lokal dipertahankan (${pendingOrLocalOnly.length})",
          level: 2,
        );
      } else {
        // Jika cloud kosong (bisa karena error atau memang kosong), jangan hapus data lokal
        print(
          'DEBUG loadLogs - Cloud returned empty, keeping local data (${refreshedLocalData.length} items)',
        );
        await LogHelper.writeLog(
          "SYNC: Cloud kosong, menggunakan data lokal (${refreshedLocalData.length} items)",
          level: 2,
        );
      }
    } catch (e) {
      // ✅ Jika offline/error, tetap gunakan data lokal (sudah di-set di atas)
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal (${localData.length} items)",
        level: 2,
      );
      print(
        'DEBUG loadLogs - Offline mode, using ${localData.length} local items',
      );
      print('DEBUG loadLogs - Error: $e');
    }
  }

  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId, {
    String visibility = 'Public', // Default: Public
    String category = 'Software', // Default: Software
  }) async {
    print('DEBUG addLog - Creating log:');
    print('  Title: $title');
    print('  Author: $authorId');
    print('  Team: $teamId');
    print('  Visibility: $visibility');

    // Mark sebagai in-flight untuk cegah auto-sync upload duplikat
    final logKey = '$title|$desc|$authorId|$teamId';
    _inFlightLogs.add(logKey);
    print('DEBUG addLog - Marked in-flight: $logKey');

    try {
      final newLog = LogModel(
        id: null,
        title: title,
        description: desc,
        date: DateTime.now().toString(),
        authorId: authorId,
        teamId: teamId,
        visibility: visibility,
        category: category,
      );

      // 🔒 SELALU simpan ke Hive dulu (offline-first)
      await _myBox.add(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];

      print('DEBUG addLog - Saved to Hive: $title');
      print('DEBUG addLog - Hive total now: ${_myBox.length}');
      print('DEBUG addLog - LogsNotifier count: ${logsNotifier.value.length}');

      // 🌐 Coba sync ke Atlas jika ada koneksi
      try {
        final insertedLog = await MongoService().insertLog(newLog);

        // ✅ Berhasil sync! Update dengan id dari MongoDB
        final syncedLog = LogModel(
          id: insertedLog.id, // Gunakan id dari MongoDB
          title: title,
          description: desc,
          date: newLog.date,
          authorId: authorId,
          teamId: teamId,
          visibility: visibility,
          category: category,
        );

        // Re-locate index karena Hive bisa berubah saat concurrent loadLogs
        final currentIndex = _findIndexInHive(newLog);
        if (currentIndex != -1) {
          await _myBox.putAt(currentIndex, syncedLog);
          print(
            'DEBUG addLog - Updated Hive at index $currentIndex with id: ${insertedLog.id}',
          );
        } else {
          // Fallback: jika tidak ketemu di Hive, add sebagai item baru
          await _myBox.add(syncedLog);
          print(
            'DEBUG addLog - WARNING: Could not find index in Hive, added as new item with id: ${insertedLog.id}',
          );
        }

        // Update UI
        final currentList = List<LogModel>.from(logsNotifier.value);
        final uiIndex = currentList.indexWhere(
          (log) =>
              log.title == title &&
              log.description == desc &&
              log.authorId == authorId &&
              log.teamId == teamId,
        );
        if (uiIndex != -1) {
          currentList[uiIndex] = syncedLog;
        } else {
          currentList.add(syncedLog);
        }
        logsNotifier.value = currentList;

        await LogHelper.writeLog(
          "ONLINE: Data '$title' berhasil ditambahkan ke Atlas",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "OFFLINE: Data '$title' tersimpan lokal (tidak sync ke Atlas) - $e",
          source: "log_controller.dart",
          level: 1,
        );
        // TIDAK rethrow agar operasi tetap dianggap berhasil
      }
    } finally {
      // Selalu hapus dari in-flight setelah selesai
      _inFlightLogs.remove(logKey);
      print('DEBUG addLog - Removed from in-flight: $logKey');
    }
  }

  /// UPDATE: Edit log yang sudah ada di MongoDB
  Future<void> updateLog(
    LogModel originalLog,
    String newTitle,
    String newDesc,
    String authorId,
    String teamId, {
    required String currentUserId,
    required String currentUserRole,
    String visibility = 'Public', // Default: Public
    String category = 'Software', // Default: Software
  }) async {
    _enforceModifyPermission(
      originalLog,
      currentUserId,
      currentUserRole,
      AccessControlService.actionUpdate,
    );

    final hiveIndex = _findIndexInHive(originalLog);
    if (hiveIndex == -1) {
      throw Exception('Data log tidak ditemukan untuk di-update');
    }

    final updatedLog = LogModel(
      id: originalLog.id,
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      visibility: visibility,
      category: category,
    );

    // 🔒 SELALU update Hive dulu (offline-first)
    await _myBox.putAt(hiveIndex, updatedLog);

    // Update list di UI
    final currentList = List<LogModel>.from(logsNotifier.value);
    final notifierIndex = _findIndexInList(currentList, originalLog);
    if (notifierIndex != -1) {
      currentList[notifierIndex] = updatedLog;
    }
    logsNotifier.value = currentList;

    // 🌐 Coba sync ke Atlas jika ada koneksi
    try {
      if (originalLog.id != null) {
        await MongoService().updateLog(updatedLog);

        await LogHelper.writeLog(
          "ONLINE: Data '$newTitle' berhasil diupdate di Atlas",
          source: "log_controller.dart",
          level: 2,
        );
      } else {
        await LogHelper.writeLog(
          "OFFLINE: Data '$newTitle' tersimpan lokal (belum punya ID Atlas)",
          source: "log_controller.dart",
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Data '$newTitle' tersimpan lokal (tidak sync ke Atlas) - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // TIDAK rethrow agar operasi tetap dianggap berhasil
    }
  }

  /// DELETE: Hapus log dari MongoDB
  Future<void> removeLog(
    LogModel targetLog, {
    required String currentUserId,
    required String currentUserRole,
  }) async {
    _enforceModifyPermission(
      targetLog,
      currentUserId,
      currentUserRole,
      AccessControlService.actionDelete,
    );

    final hiveIndex = _findIndexInHive(targetLog);
    if (hiveIndex == -1) {
      throw Exception('Data log tidak ditemukan untuk dihapus');
    }

    // 🔒 SELALU hapus dari Hive dulu (offline-first)
    await _myBox.deleteAt(hiveIndex);

    // Perbarui tampilan UI
    final currentList = List<LogModel>.from(logsNotifier.value);
    final notifierIndex = _findIndexInList(currentList, targetLog);
    if (notifierIndex != -1) {
      currentList.removeAt(notifierIndex);
    }
    logsNotifier.value = currentList;

    // 🌐 Coba sync ke Atlas jika ada koneksi
    try {
      if (targetLog.id != null) {
        await MongoService().deleteLog(ObjectId.fromHexString(targetLog.id!));

        await LogHelper.writeLog(
          "ONLINE: Data berhasil dihapus dari Atlas",
          source: "log_controller.dart",
          level: 2,
        );
      } else {
        await LogHelper.writeLog(
          "OFFLINE: Data dihapus lokal (belum punya ID Atlas)",
          source: "log_controller.dart",
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Data dihapus lokal (tidak sync ke Atlas) - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // TIDAK rethrow agar operasi tetap dianggap berhasil
    }
  }
}
