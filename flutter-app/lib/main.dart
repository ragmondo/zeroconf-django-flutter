import 'package:flutter/material.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mDNS Discovery',
      home: const DiscoveryPage(),
    );
  }
}

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  BonsoirDiscovery? discovery;
  final List<ResolvedBonsoirService> services = [];
  String? response;

  @override
  void dispose() {
    discovery?.stop();
    super.dispose();
  }

  Future<void> startDiscovery() async {
    setState(() {
      services.clear();
      response = null;
    });

    discovery = BonsoirDiscovery(type: '_django-api._tcp');
    await discovery!.ready;

    discovery!.eventStream?.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        if (event.service is ResolvedBonsoirService) {
          setState(() {
            final resolved = event.service as ResolvedBonsoirService;
            if (!services.any((s) => s.name == resolved.name)) {
              services.add(resolved);
            }
          });
        }
      }
    });

    await discovery!.start();
  }

  Future<void> testConnection(ResolvedBonsoirService service) async {
    try {
      final url = Uri.parse('http://${service.host}:${service.port}/api/test/');
      final res = await http.get(url);

      setState(() {
        response = res.statusCode == 200
          ? json.decode(res.body)['message']
          : 'Error: ${res.statusCode}';
      });
    } catch (e) {
      setState(() => response = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mDNS Discovery')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: startDiscovery,
              child: const Text('Discover Services'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ListTile(
                  title: Text(service.name ?? 'Unknown'),
                  subtitle: Text('${service.host}:${service.port}'),
                  trailing: ElevatedButton(
                    onPressed: () => testConnection(service),
                    child: const Text('Test'),
                  ),
                );
              },
            ),
          ),
          if (response != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green[100],
              child: Text(response!),
            ),
        ],
      ),
    );
  }
}