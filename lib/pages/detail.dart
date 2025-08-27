import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is the detail page'),
            const SizedBox(height: 16),
            const Hero(
              tag: 'plus-hero', // 👈 ต้องตรงกับ HomeScreen
              child: Image(
                image: AssetImage('assets/images/Dog.jpg'), // 👈 path ที่ถูก
                width: 200,
                height: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
