// Model untuk tipe log
enum LogType { tambah, kurang, reset }

// Model untuk entry log
class LogEntry {
  final LogType type;
  final String message;
  final String time;
  
  LogEntry(this.type, this.message, this.time);
}

class CounterController {
  int _counter = 0; 
  int _step = 1;
  
  int get value => _counter; 
  int get step => _step;
  
  final List<LogEntry> _history = [];

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
    if(_step > 0) { 
      _counter += _step;
      _history.insert(0, LogEntry(
        LogType.tambah,
        "User menambah $_step",
        _getTime()
      ));
    }
  }
  
  void setStep(int newStep) => _step = newStep;

  void decrement() { 
    if (_counter > 0) {
      _counter -= _step; 
      _history.insert(0, LogEntry(
        LogType.kurang,
        "User mengurangi $_step",
        _getTime()
      ));
    }
  }

  void reset() {
    _counter = 0;
    _history.insert(0, LogEntry(
      LogType.reset,
      "Logbook di reset",
      _getTime()
    ));
  }
}