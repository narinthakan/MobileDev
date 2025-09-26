import 'package:flutter/material.dart';
import 'pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DSSIShop',
      debugShowCheckedModeBanner: false, // ✅ ซ่อนแถบ DEBUG มุมขวาบน
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          primary: Colors.lightBlue.shade700,
          secondary: Colors.lightBlue.shade200,
          background: Colors.lightBlue.shade50,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.lightBlue.shade50,
        fontFamily: 'Prompt', // ใช้ GoogleFonts.prompt
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
