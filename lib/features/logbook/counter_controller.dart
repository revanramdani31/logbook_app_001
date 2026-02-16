import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Model untuk tipe log
enum LogType { tambah, kurang, reset }

// Model untuk entry log
class LogEntry {
  final LogType type;
  final String message;
  final String time;

  LogEntry({required this.type, required this.message, required this.time});

  Map<String, dynamic> toMap() {
    return {
      'type': type.name, // Convert enum to string
      'message': message,
      'time': time,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      type: LogType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => LogType.tambah,
      ),
      message: map['message'] ?? '',
      time: map['time'] ?? '',
    );
  }
}

class CounterController {
  int _counter = 0;
  int _step = 1;

  int get value => _counter;
  int get step => _step;

  final List<LogEntry> _history = [];

  static const String _keyCounter = 'counter_value';
  static const String _keyStep = 'step_value';
  static const String _keyHistory = 'history_logs';

  String _getTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  List<LogEntry> get recentHistory {
    return _history.take(5).toList();
  }

  void increment() {
    if (_step > 0) {
      _counter += _step;
      _history.insert(
        0,
        LogEntry(
          type: LogType.tambah,
          message: "User menambah $_step",
          time: _getTime(),
        ),
      );
      _saveToLocal();
    }
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCounter, _counter);
    await prefs.setInt(_keyStep, _step);
    List<String> rawLogs = _history
        .map((log) => jsonEncode(log.toMap()))
        .toList();
    await prefs.setStringList(_keyHistory, rawLogs);
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt(_keyCounter) ?? 0;
    _step = prefs.getInt(_keyStep) ?? 1;
    List<String>? rawLogs = prefs.getStringList(_keyHistory);
    if (rawLogs != null) {
      _history.clear();
      for (var item in rawLogs) {
        _history.add(LogEntry.fromMap(jsonDecode(item)));
      }
    }
  }

  void setStep(int newStep) => _step = newStep;

  void decrement() {
    if (_counter > 0) {
      _counter -= _step;
      _history.insert(
        0,
        LogEntry(
          type: LogType.kurang,
          message: "User mengurangi $_step",
          time: _getTime(),
        ),
      );
      _saveToLocal();
    }
  }

  void reset() {
    _counter = 0;
    _history.insert(
      0,
      LogEntry(
        type: LogType.reset,
        message: "Logbook di reset",
        time: _getTime(),
      ),
    );
    _saveToLocal();
  }
}
