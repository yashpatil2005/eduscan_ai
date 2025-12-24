import 'package:flutter/material.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Notes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded, size: 80, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text('This will be your scanner screen ✨'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // We’ll add image picker and OCR here later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Scanner coming soon!')),
                );
              },
              child: Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
