import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

/// LogController: Handle business logic untuk ADD, UPDATE, DELETE
/// READ logic ada di View (FutureBuilder)
class LogController {
  final String username;

  LogController({required this.username});

  /// CREATE: Tambah log baru ke MongoDB
  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );

    try {
      // Kirim ke MongoDB Atlas
      await MongoService().insertLog(newLog);

      await LogHelper.writeLog(
        "SUCCESS: Data '$title' berhasil ditambahkan",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal menambah data - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow; // Lempar error ke View untuk ditampilkan
    }
  }

  /// UPDATE: Edit log yang sudah ada di MongoDB
  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String category, {
    ObjectId? logId, // Tambah optional parameter untuk ID
  }) async {
    try {
      if (logId == null) {
        throw Exception("ID log tidak ditemukan untuk update");
      }

      final updatedLog = LogModel(
        id: logId,
        title: newTitle,
        description: newDesc,
        category: category,
        date: DateTime.now().toString(),
      );

      // Update ke MongoDB Atlas
      await MongoService().updateLog(updatedLog);

      await LogHelper.writeLog(
        "SUCCESS: Data '$newTitle' berhasil diupdate",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal update data - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE: Hapus log dari MongoDB
  Future<void> removeLog(int index, {ObjectId? logId}) async {
    try {
      if (logId == null) {
        throw Exception("ID log tidak ditemukan untuk hapus");
      }

      // Hapus data di MongoDB Atlas
      await MongoService().deleteLog(logId);

      await LogHelper.writeLog(
        "SUCCESS: Data berhasil dihapus",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal hapus data - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }
}
