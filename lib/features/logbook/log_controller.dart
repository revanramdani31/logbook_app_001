import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogController {
  final String username;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  String get _storageKey => 'user_logs_data_$username';

  LogController({required this.username}) {
    loadFromDisk();
  }

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

  void addLog(String title, String desc, String category) {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = List<LogModel>.from(logsNotifier.value);
    saveToDisk();
  }

  void updateLog(int index, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );
    logsNotifier.value = currentLogs;
    filteredLogs.value = List<LogModel>.from(currentLogs);
    saveToDisk();
  }

  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    filteredLogs.value = List<LogModel>.from(currentLogs);
    saveToDisk();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
      filteredLogs.value = List<LogModel>.from(logsNotifier.value);
    }
  }
}
