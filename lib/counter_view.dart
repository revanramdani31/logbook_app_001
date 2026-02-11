import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepInput = TextEditingController();

  Color getColorForLogType(LogType type) {
    switch (type) {
      case LogType.tambah:
        return Colors.green;
      case LogType.kurang:
        return Colors.red;
      case LogType.reset:
        return Colors.orange;
    }
  }
  
  // Helper method untuk icon
  IconData getIconForLogType(LogType type) {
    switch (type) {
      case LogType.tambah:
        return Icons.add_circle;
      case LogType.kurang:
        return Icons.remove_circle;
      case LogType.reset:
        return Icons.refresh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Align(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 50.0,
                vertical: 10.0,
              ),
              child: TextField(
                controller: _stepInput,
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  int? input = int.tryParse(val);
                  if (input != null) {
                    _controller.setStep(input);
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Input angka step",
                  hintText: "Contoh: 5",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 20),
            Text("Nilai  step saat ini: ${_controller.step}"),
            const Text(
              "5 Riwayat Terakhir:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _controller.recentHistory.length,
              itemBuilder: (context, index) {
                final LogEntry log = _controller.recentHistory[index];
                final Color textColor = getColorForLogType(log.type);
                final IconData icon = getIconForLogType(log.type);

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: textColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: textColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${log.message} pada ${log.time}",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100, width: 20),
          FloatingActionButton(
            heroTag: "increment",
            backgroundColor: Colors.green,
            onPressed: () => setState(() => _controller.increment()),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 100, width: 20),
          FloatingActionButton(
            heroTag: "decrement",
            backgroundColor: Colors.red,
            onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 100, width: 20),
          FloatingActionButton(
            heroTag: "reset",
            backgroundColor: Colors.orange,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Reset"),
                    content: const Text(
                      "Apakah Anda yakin ingin menghapus semua hitungan?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _controller.reset());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("hitungan telah berhasil di-reset!"),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating, 
                            ),
                          );
                        },
                        child: const Text(
                          "Ya, Reset",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
