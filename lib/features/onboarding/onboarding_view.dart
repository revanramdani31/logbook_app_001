import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  // Variabel untuk melacak langkah onboarding
  int step = 1;

  void nextStep() {
    setState(() {
      if (step < 3) {
        step++; // Menambah step jika belum mencapai maksimal
      } else {
        // Jika step > 3, pindah ke LoginView
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: const Text("Counter Logbook")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOnboardingContent(),
            const SizedBox(height: 10),
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(1), // Titik untuk step 1
              _buildDot(2), // Titik untuk step 2
              _buildDot(3), // Titik untuk step 3
            ],
          ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: nextStep,
              child: Text(step == 3 ? "Mulai Sekarang" : "Next"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingContent() {
    switch (step) {
      case 1:
        return Column(
          children: [
            Image.asset(
              'assets/counter.png',
              height: 200, 
            ),
            const SizedBox(height: 20),
            const Text("Selamat Datang di Aplikasi Counter Logbook!"),
          ],
        );
      case 2:
        return Column(
          children: [
            Image.asset('assets/6.gif', height: 200),
            const SizedBox(height: 20),
            const Text("Hitung setiap aktivitasmu."),
          ],
        );
      case 3:
        return Column(
          children: [
            Image.asset('assets/5.gif', height: 200),
            const SizedBox(height: 20),
            const Text("Siap dimulai!"),
          ],
        ); 
      default:
        return const SizedBox();
    }
  }
  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: step == index ? Colors.blue : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
