import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../view_models/scanning_vm.dart';
import '../providers.dart';
import '../services/export_service.dart';

class ScanResultsScreen extends ConsumerWidget {
  const ScanResultsScreen({super.key});

  Future<void> _handleExport(BuildContext context, ExportService exportService) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating export...'),
            ],
          ),
        ),
      );

      // Perform export
      await exportService.exportToZip();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final exportService = ref.watch(exportServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export',
            onPressed: () => _handleExport(context, exportService),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No transactions recorded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start scanning products to see transaction history',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group transactions by product
          final groupedTransactions = <String, List<Transaction>>{};
          for (final transaction in transactions) {
            groupedTransactions.putIfAbsent(transaction.productId, () => []).add(transaction);
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isPositive = transaction.quantity > 0;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPositive ? Colors.green : Colors.red,
                    child: Icon(
                      isPositive ? Icons.add : Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    transaction.productId,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    DateFormat.yMd().add_jms().format(transaction.timestamp.toLocal()),
                  ),
                  trailing: Text(
                    '${transaction.quantity > 0 ? '+' : ''}${transaction.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
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