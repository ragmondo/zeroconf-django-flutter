import 'package:flutter/material.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mDNS Discovery Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ServiceDiscoveryPage(),
    );
  }
}

class ServiceDiscoveryPage extends StatefulWidget {
  const ServiceDiscoveryPage({super.key});

  @override
  State<ServiceDiscoveryPage> createState() => _ServiceDiscoveryPageState();
}

class _ServiceDiscoveryPageState extends State<ServiceDiscoveryPage> {
  BonsoirDiscovery? discovery;
  final List<ResolvedBonsoirService> discoveredServices = [];
  String? serverResponse;
  bool isDiscovering = false;

  @override
  void dispose() {
    discovery?.stop();
    super.dispose();
  }

  Future<void> startDiscovery() async {
    print('=== STARTING DISCOVERY ===');

    // Try both service types
    final serviceType = '_django-api._tcp';
    print('Looking for service type: $serviceType');

    setState(() {
      discoveredServices.clear();
      isDiscovering = true;
      serverResponse = null;
    });

    discovery = BonsoirDiscovery(type: serviceType);
    print('Discovery instance created for type: $serviceType');

    // Wait for the discovery to be ready
    print('Waiting for discovery to be ready...');
    await discovery!.ready;
    print('Discovery is ready');

    discovery!.eventStream?.listen(
      (event) {
        print('=== DISCOVERY EVENT ===');
        print('Event type: ${event.type}');
        print('Service: ${event.service}');

        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          print('SERVICE FOUND: ${event.service?.name}');
          print('Service type: ${event.service?.type}');
          print('Attempting to resolve...');
          event.service?.resolve(discovery!.serviceResolver);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          print('SERVICE RESOLVED:');
          print('  Name: ${event.service?.name}');
          print('  Type: ${event.service?.type}');
          print('  Full JSON: ${event.service?.toJson()}');

          if (event.service is ResolvedBonsoirService) {
            final resolved = event.service as ResolvedBonsoirService;
            print('  Host: ${resolved.host}');
            print('  Port: ${resolved.port}');
            print('  Attributes: ${resolved.attributes}');

            setState(() {
              if (!discoveredServices.any((s) => s.name == resolved.name)) {
                discoveredServices.add(resolved);
                print('Added service to list. Total services: ${discoveredServices.length}');
              }
            });
          }
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          print('SERVICE LOST: ${event.service?.name}');
          setState(() {
            discoveredServices.removeWhere((s) => s.name == event.service?.name);
          });
        } else {
          print('Unknown event type: ${event.type}');
        }
      },
      onError: (error, stackTrace) {
        print('=== DISCOVERY ERROR ===');
        print('Error: $error');
        print('Stack trace: $stackTrace');
      },
    );

    print('Starting discovery...');
    await discovery!.start();
    print('Discovery started successfully');

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && isDiscovering) {
        print('Auto-stopping discovery after 10 seconds...');
        stopDiscovery();
      }
    });
  }

  Future<void> stopDiscovery() async {
    print('=== STOPPING DISCOVERY ===');
    await discovery?.stop();
    setState(() {
      isDiscovering = false;
    });
    print('Discovery stopped');
  }

  Future<void> testServerConnection(ResolvedBonsoirService service) async {
    try {
      final host = service.host;
      final port = service.port;

      if (host == null || port == null) {
        setState(() {
          serverResponse = 'Error: Missing host or port information';
        });
        return;
      }

      final url = Uri.parse('http://$host:$port/api/info/');
      print('Connecting to: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final encoder = JsonEncoder.withIndent('  ');
          serverResponse = 'Server Response:\n${encoder.convert(data)}';
        });
      } else {
        setState(() {
          serverResponse = 'Error: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        serverResponse = 'Connection Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('mDNS Service Discovery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: isDiscovering ? null : startDiscovery,
                  child: const Text('Start Discovery'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isDiscovering ? stopDiscovery : null,
                  child: const Text('Stop Discovery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDiscovering)
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Discovered Services (${discoveredServices.length}):',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: discoveredServices.length,
                itemBuilder: (context, index) {
                  final service = discoveredServices[index];
                  return Card(
                    child: ListTile(
                      title: Text(service.name ?? 'Unknown Service'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Host: ${service.host ?? "Unknown"}'),
                          Text('Port: ${service.port ?? "Unknown"}'),
                          if (service.attributes != null)
                            Text('Attributes: ${service.attributes}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => testServerConnection(service),
                        child: const Text('Test'),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (serverResponse != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  serverResponse!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}