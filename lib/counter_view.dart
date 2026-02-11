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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
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
            const SizedBox(height: 30),
            Text("Nilai  step saat ini: ${_controller.step}"),
            const Text("5 Riwayat Terakhir:", style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              // View tinggal pakai, tidak perlu logika perbandingan lagi
              itemCount: _controller.recentHistory.length, 
              itemBuilder: (context, index) {
                return Text(_controller.recentHistory[index]);
              },
            )
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "increment",
            onPressed: () => setState(() => _controller.increment()),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "decrement",
            onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "reset",
            onPressed: () => setState(() => _controller.reset()),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
    
  }
}