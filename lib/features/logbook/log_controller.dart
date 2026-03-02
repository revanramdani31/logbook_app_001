import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Wajib ditambahkan untuk jsonEncode & jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  final String username;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  String get _storageKey => 'user_logs_data_$username';
  List<LogModel> get logs => logsNotifier.value;

  LogController({required this.username});

  void searchLog(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      filteredLogs.value = List<LogModel>.from(logsNotifier.value);
    } else {
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(trimmedQuery.toLowerCase()) ||
                log.description.toLowerCase().contains(
                  trimmedQuery.toLowerCase(),
                ) ||
                log.category.toLowerCase().contains(trimmedQuery.toLowerCase()),
          )
          .toList();
    }
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawJson = prefs.getString('saved_logs');

    if (rawJson != null) {
      Iterable decoded = jsonDecode(rawJson);
      logsNotifier.value = decoded
          .map((item) => LogModel.fromMap(item))
          .toList();
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );

    try {
      // 2. Kirim ke MongoDB Atlas
      await MongoService().insertLog(newLog);

      // 3. Update UI Lokal (Data sekarang sudah punya ID asli)
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Tambah data dengan ID lokal",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkronisasi Add - $e", level: 1);
    }
  }

  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String Category,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama agar MongoDB mengenali dokumen ini
      title: newTitle,
      description: newDesc,
      category: Category,
      date: DateTime.now().toString(),
    );

    try {
      // 1. Jalankan update di MongoService (Tunggu konfirmasi Cloud)
      await MongoService().updateLog(updatedLog);

      // 2. Jika sukses, baru perbarui state lokal
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${oldLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // Data di UI tidak berubah jika proses di Cloud gagal
    }
  }

  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    try {
      if (targetLog.id == null) {
        throw Exception(
          "ID Log tidak ditemukan, tidak bisa menghapus di Cloud.",
        );
      }

      // 1. Hapus data di MongoDB Atlas (Tunggu konfirmasi Cloud)
      await MongoService().deleteLog(targetLog.id!);

      // 2. Jika sukses, baru hapus dari state lokal
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${targetLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    // Mengubah List of Object -> List of Map -> String JSON
    final String encodedData = jsonEncode(
      logsNotifier.value.map((log) => log.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    // Mengambil dari Cloud, bukan lokal
    final cloudData = await MongoService().getLogs();
    logsNotifier.value = cloudData;
    filteredLogs.value = List<LogModel>.from(cloudData);
  }
}
