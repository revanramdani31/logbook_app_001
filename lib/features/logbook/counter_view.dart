import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});

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
  void initState() {
    super.initState();
    // Memuat data spesifik milik user yang sedang login
    _controller.loadData(widget.username).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text(
                      "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingView(),
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
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "${_controller.getGreeting()}, ${widget.username}!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 2, 5),
              ),
            ),
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
                    _controller.setStep(input, widget.username);
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
            const SizedBox(height: 80), // Spacing untuk floating button
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: "increment",
            backgroundColor: Colors.green,
            onPressed: () =>
                setState(() => _controller.increment(widget.username)),
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "decrement",
            backgroundColor: Colors.red,
            onPressed: () =>
                setState(() => _controller.decrement(widget.username)),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 16),
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
                          setState(() => _controller.reset(widget.username));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "hitungan telah berhasil di-reset!",
                              ),
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
