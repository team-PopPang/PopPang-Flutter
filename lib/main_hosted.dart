import 'package:flutter/material.dart';

void main() {
  runHostedApp();
}

void runHostedApp() {
  runApp(const PopPangHostedApp());
}

class PopPangHostedApp extends StatelessWidget {
  const PopPangHostedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PopPang Flutter Hosted',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('Hosted Mode'))),
    );
  }
}
