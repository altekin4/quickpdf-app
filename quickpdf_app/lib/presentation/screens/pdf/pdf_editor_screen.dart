import 'package:flutter/material.dart';

class PDFEditorScreen extends StatefulWidget {
  final String? templateId;

  const PDFEditorScreen({super.key, this.templateId});

  @override
  State<PDFEditorScreen> createState() => _PDFEditorScreenState();
}

class _PDFEditorScreenState extends State<PDFEditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Editör'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'PDF Editör',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Bu özellik yakında gelecek',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}