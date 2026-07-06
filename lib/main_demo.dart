import 'package:flutter/material.dart';

void main() {
  runDemoApp();
}

void runDemoApp() {
  runApp(const PopPangDemoApp());
}

class PopPangDemoApp extends StatelessWidget {
  const PopPangDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PopPang Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PopPang Flutter Module',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'This default entry point boots the module in demo mode.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current setup', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    const Text(
                      '- Hosted entry: lib/main.dart -> lib/main_hosted.dart',
                    ),
                    const Text(
                      '- Demo run: flutter run --target lib/main_demo.dart',
                    ),
                    const Text('- Mode: Demo'),
                    const Text(
                      '- First feature target: admin.popup_management',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
