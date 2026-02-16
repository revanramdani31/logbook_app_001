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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan indikator step saat ini
            Text(
              "Halamanan onboarding",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "$step",
              style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold),
            ),
            _buildOnboardingContent(),
            // Tombol Next
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
              'assets/1.jpeg',
              height: 200, // Atur tinggi gambar
            ),
            const SizedBox(height: 20),
            const Text("Selamat Datang di LogBook App!"),
          ],
        );
      case 2:
        return Column(
          children: [
            // Contoh menggunakan gambar dari internet
            Image.asset('assets/2.jpeg', height: 200),
            const SizedBox(height: 20),
            const Text("Catat setiap perubahan hitunganmu."),
          ],
        );
      case 3:
        return Column(
          children: [
            Image.asset('assets/3.jpeg', height: 200),
            const SizedBox(height: 20),
            const Text("Siap dimulai!"),
          ],
        ); // Kamu juga bisa pakai Icon sebagai pengganti gambar
      default:
        return const SizedBox();
    }
  }
}
