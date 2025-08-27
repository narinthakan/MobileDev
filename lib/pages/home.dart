import 'package:flutter/material.dart';
import 'package:myapp/pages/detail.dart'; // import ให้ตรงกับโครงสร้าง

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _imagePath = 'assets/images/Dog.jpg'; // ✅ แก้ path ให้ตรงกับ pubspec.yaml

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    // ✅ เรียก DetailScreen ให้ตรงกับไฟล์ detail.dart
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DetailScreen()),
    );
  }

  void setImagePath(String path) {
    setState(() {
      _imagePath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build MyHomePage: $_counter, $_imagePath');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text('$_counter',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Image.asset(_imagePath, width: 120, height: 120), // ✅ แสดงรูป
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
