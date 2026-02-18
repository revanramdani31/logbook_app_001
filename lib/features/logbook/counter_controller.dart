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

  String _getCounterKey(String username) => '${username}_counter_value';
  String _getHistoryKey(String username) => '${username}_history_logs';
  String _getStepKey(String username) => '${username}_step_value';

  String _getTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 11) {
      return "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  List<LogEntry> get recentHistory {
    return _history.take(5).toList();
  }

  Future<void> saveData(String username) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_getCounterKey(username), _counter);
      await prefs.setInt(_getStepKey(username), _step);
      
      List<String> rawLogs = _history.map((log) => jsonEncode(log.toMap())).toList();
      await prefs.setStringList(_getHistoryKey(username), rawLogs);
    }

  Future<void> loadData(String username) async {
      final prefs = await SharedPreferences.getInstance();
      _counter = prefs.getInt(_getCounterKey(username)) ?? 0;
      _step = prefs.getInt(_getStepKey(username)) ?? 1;

      List<String>? rawLogs = prefs.getStringList(_getHistoryKey(username));
      _history.clear();
      if (rawLogs != null) {
        for (var item in rawLogs) {
          _history.add(LogEntry.fromMap(jsonDecode(item)));
        }
      }
    }
    void increment(String username) {
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
      saveData(username);
    }
  }

  void setStep(int newStep, String username) {
    _step = newStep;
    saveData(username); 
  }

  void decrement(String username) {
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
      saveData(username);
    }
  }

  void reset(String username) {
    _counter = 0;
    _history.insert(
      0,
      LogEntry(
        type: LogType.reset,
        message: "Logbook di reset",
        time: _getTime(),
      ),
    );
    saveData(username);
  }
}
