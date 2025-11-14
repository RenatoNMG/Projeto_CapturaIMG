import 'dart:io';
import 'package:flutter/material.dart';

class FullImagePage extends StatelessWidget {
  final File file;
  const FullImagePage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar imagem')),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }
}
