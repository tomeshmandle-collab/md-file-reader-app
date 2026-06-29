import 'package:flutter/material.dart';

class ReaderScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const ReaderScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: Center(
        child: Text('Reader Screen Stub for:\n$filePath'),
      ),
    );
  }
}
