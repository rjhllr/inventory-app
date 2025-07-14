import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../view_models/scanning_vm.dart';
import '../providers.dart';
import '../services/export_service.dart';
import '../l10n/app_localizations.dart';
import '../datetime_utils.dart';

class ScanResultsScreen extends ConsumerWidget {
  const ScanResultsScreen({super.key});

  Future<void> _handleExport(BuildContext context, ExportService exportService) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n.generatingExport),
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
          SnackBar(
            content: Text(l10n.exportCompletedSuccessfully),
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
            content: Text(l10n.exportFailed(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.export,
            onPressed: () => _handleExport(context, exportService),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTransactionsRecordedYet,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.startScanningToSeeHistory,
                    style: const TextStyle(color: Colors.grey),
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
                    DateTimeUtils.formatScanTime(context, transaction.timestamp.toLocal()),
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