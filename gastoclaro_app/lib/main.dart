import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'services/ping_service.dart';

void main() {
  runApp(const GastoClaroApp());
}

class GastoClaroApp extends StatelessWidget {
  const GastoClaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastoClaro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const PingPage(),
    );
  }
}

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  late Future<Map<String, dynamic>> futurePing;
  final PingService pingService = PingService();

  @override
  void initState() {
    super.initState();
    futurePing = pingService.ping();
  }

  void retry() {
    setState(() {
      futurePing = pingService.ping();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GastoClaro API Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<Map<String, dynamic>>(
            future: futurePing,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting to API...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Base URL: ${ApiConfig.baseUrl}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: retry,
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }

              final data = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'API connected successfully',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Message: ${data['message']}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'App: ${data['app']}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Base URL: ${ApiConfig.baseUrl}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: retry,
                    child: const Text('Reload'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}