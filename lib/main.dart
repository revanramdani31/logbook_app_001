import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load ENV
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('offline_logs');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OnboardingView(),
    );
  }
}
