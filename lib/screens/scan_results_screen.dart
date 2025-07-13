import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../view_models/scanning_vm.dart';

class ScanResultsScreen extends ConsumerWidget {
  const ScanResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(scansStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon.')),
              );
            },
          ),
        ],
      ),
      body: scansAsync.when(
        data: (scans) {
           if (scans.isEmpty) {
            return const Center(child: Text('No scans recorded yet.'));
          }
          return ListView.builder(
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              return ListTile(
                title: Text(scan.productId),
                subtitle: Text(DateFormat.yMd().add_jms().format(scan.timestamp.toLocal())),
                trailing: Text('Quantity: ${scan.quantity}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
} 