import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/view_models/reset_stocks_vm.dart';
import '../providers.dart';
import '../l10n/app_localizations.dart';
import '../datetime_utils.dart';

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
      await dataSource.deleteAllPromptQuestions();
      
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allDataPermanentlyDeleted),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDeleteData(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showResetAllDataConfirmationDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.deleteAllData),
          ],
        ),
        content: Text(
          '${l10n.actionCannotBeUndone}\n\n'
          '${l10n.willPermanentlyDelete}\n'
          '• ${l10n.allScannedProducts}\n'
          '• ${l10n.allTransactionHistory}\n'
          '• ${l10n.allPromptAnswers}\n'
          '• ${l10n.allCustomPromptQuestions}\n\n'
          '${l10n.absolutelySureToContinue}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAllCaps),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsWithTransactions = ref.watch(productsWithTransactionsProvider);
    final vm = ref.read(resetStocksVmProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetStocksData),
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
                        Text(
                          l10n.removeAllData,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.permanentDeletionWarning,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: Text(l10n.removeAllDataButton),
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
                        Text(
                          l10n.stockResetInformation,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.stockResetExplanation,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.resetAllStocksButton),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          l10n.allStocksAtZero,
                          style: const TextStyle(fontSize: 18, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noProductsToReset,
                          style: const TextStyle(color: Colors.grey),
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
                        subtitle: Text(l10n.lastUpdated(DateTimeUtils.formatLastUpdated(context, product.updatedAt.toLocal()))),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: l10n.resetThisProductStock,
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
              error: (e, s) => Center(child: Text(l10n.errorMessage(e.toString()))),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetAllConfirmationDialog(BuildContext context, ResetStocksVm vm) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetAllStocks),
        content: Text(l10n.resetAllStocksDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.resetAllStocks();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allStocksResetToZero),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(l10n.resetAll),
          ),
        ],
      ),
    );
  }

  void _showResetProductConfirmationDialog(BuildContext context, String productId, ResetStocksVm vm) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetProductStock),
        content: Text(l10n.resetProductStockDescription(productId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.resetStockForProduct(productId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.stockResetToZero(productId)),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
} 