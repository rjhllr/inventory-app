import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/view_models/reset_stocks_vm.dart';
import '../providers.dart';

class ResetStocksScreen extends ConsumerWidget {
  const ResetStocksScreen({super.key});

  Future<void> _handleResetAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showResetAllDataConfirmationDialog(context);
    if (!confirmed) return;

    try {
      final dataSource = ref.read(dataSourceProvider);
      
      // Delete all data (order matters due to foreign key constraints)
      await dataSource.deleteAllTransactions(); // This also deletes prompt answers
      await dataSource.deleteAllProducts();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been permanently deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showResetAllDataConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete All Data'),
          ],
        ),
        content: const Text(
          'THIS ACTION CANNOT BE UNDONE!\n\n'
          'This will permanently delete:\n'
          '• All scanned products\n'
          '• All transaction history\n'
          '• All prompt answers\n\n'
          'Are you absolutely sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsWithTransactions = ref.watch(productsWithTransactionsProvider);
    final vm = ref.read(resetStocksVmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Stocks / Data'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Remove All Data Button - Most destructive action at the top
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.delete_forever, color: Colors.red, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Remove All Data',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PERMANENT DELETION: This will completely remove all products, transactions, and history. This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('REMOVE ALL DATA'),
                          onPressed: () => _handleResetAllData(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stock Reset Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Stock Reset Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Resetting stocks creates negative transactions that bring each product\'s stock to zero. This maintains a complete audit trail of all stock movements.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset All Stocks'),
                          onPressed: () => _showResetAllConfirmationDialog(context, vm),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: productsWithTransactions.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'All stocks are at zero',
                          style: TextStyle(fontSize: 18, color: Colors.green),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No products currently have stock to reset',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(product.id),
                        subtitle: Text('Last updated: ${product.updatedAt.toLocal()}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Reset this product stock',
                          onPressed: () => _showResetProductConfirmationDialog(
                            context,
                            product.id,
                            vm,
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
          ),
        ],
      ),
    );
  }

  void _showResetAllConfirmationDialog(BuildContext context, ResetStocksVm vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Stocks'),
        content: const Text(
          'This will create negative transactions to bring all product stocks to zero. '
          'The transaction history will be preserved for audit purposes.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.resetAllStocks();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All stocks have been reset to zero'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showResetProductConfirmationDialog(BuildContext context, String productId, ResetStocksVm vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Product Stock'),
        content: Text(
          'This will create a negative transaction to bring the stock of "$productId" to zero. '
          'The transaction history will be preserved for audit purposes.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.resetStockForProduct(productId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock for "$productId" has been reset to zero'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 