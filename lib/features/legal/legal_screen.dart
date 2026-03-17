import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}
