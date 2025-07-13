import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/view_models/reset_stocks_vm.dart';

class ResetStocksScreen extends ConsumerWidget {
  const ResetStocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsWithScans = ref.watch(productsWithScansProvider);
    final vm = ref.read(resetStocksVmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Stocks'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Delete All Scans'),
              onPressed: () => _showConfirmationDialog(context, () => vm.deleteAllScans()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: productsWithScans.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('All stock data has been cleared.'));
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.id),
                      subtitle: Text('Last updated: ${product.updatedAt.toLocal()}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showConfirmationDialog(
                          context,
                          () => vm.deleteScansForProduct(product.id),
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

  Future<void> _showConfirmationDialog(BuildContext context, VoidCallback onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
} 