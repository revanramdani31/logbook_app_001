class CounterController {
  int _counter = 0; 
  int _step = 1;
  int get value => _counter; 
  int get step => _step;
  List<String> get history => _history;
  final List<String> _history = [];
  List<String> get allHistory => _history;

  String _getTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  List<String> get recentHistory {
    return _history.take(5).toList();
  }

  void increment() {
    _counter += _step;
    _history.insert(0, "User menambah nilai sebesar $_step pada jam ${_getTime()}");
  }
  void setStep(int newStep) => _step = newStep;

  void decrement() { 
    if (_counter > 0) {
      _counter -= _step; 
      _history.insert(0, "User mengurangi nilai sebesar $_step pada jam ${_getTime()}");
    }
  }

  void reset()  {
   _counter = 0;
   _history.insert(0, "LogBook di-reset pada jam ${_getTime()}");
  }
}