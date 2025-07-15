import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../data/app_database.dart';
import '../view_models/scanning_vm.dart';
import '../l10n/app_localizations.dart';
import '../datetime_utils.dart';
import '../screens/attribute_values_screen.dart'; // Added import for AttributeValuesScreen

// Add provider for once attributes per product
final productOnceAttributesProvider = FutureProvider.autoDispose.family<Map<String, String>, String>((ref, productId) async {
  final vm = ref.read(scanningVmProvider);
  return vm.getOnceAttributesForProduct(productId);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(productTransactionsStreamProvider(productId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(productId),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showProductInfo(context),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.detailsTab),
              Tab(text: AppLocalizations.of(context)!.transactionsTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DetailsTab(productId: productId),
            transactionsAsync.when(
              data: (transactions) => _TransactionsTab(transactions: transactions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ],
        ),
      ),
    );
  }
  

  
  String _getTransactionDescription(BuildContext context, Transaction transaction) {
    final l10n = AppLocalizations.of(context)!;
    if (transaction.quantity > 0) {
      return l10n.stockAddition;
    } else {
      return l10n.stockReduction;
    }
  }
  
  void _showProductInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.productInformationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.productIdLabel(productId)),
            const SizedBox(height: 8),
            Text(l10n.productInfoDescription),
            const SizedBox(height: 8),
            Text(l10n.positiveQuantitiesInfo),
            Text(l10n.negativeQuantitiesInfo),
            Text(l10n.currentStockInfo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(AppLocalizations.of(context)!.photoViewerTitle(initialIndex + 1, photos.length)),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photoPath = photos[index];
                    final file = File(photoPath);
                    final fileExists = file.existsSync();
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: fileExists
                            ? Image.file(
                                file,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 64,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error loading image',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          photoPath,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.fileNotFound,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      photoPath,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsTab extends ConsumerWidget {
  final String productId;
  const _DetailsTab({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(productTransactionsStreamProvider(productId));
    return transactionsAsync.when(
      data: (transactions) {
        // Calculate summary statistics
        final totalQuantity = transactions.fold<int>(0, (sum, t) => sum + t.quantity);
        final totalTransactions = transactions.length;
        final positiveTransactions = transactions.where((t) => t.quantity > 0).length;
        final negativeTransactions = transactions.where((t) => t.quantity < 0).length;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary card (reused from original implementation)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.stockSummary,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.currentStock,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '$totalQuantity',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: totalQuantity >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.totalTransactions,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '$totalTransactions',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(
                            icon: Icons.add,
                            label: AppLocalizations.of(context)!.additions,
                            value: '$positiveTransactions',
                            color: Colors.green,
                          ),
                          _StatChip(
                            icon: Icons.remove,
                            label: AppLocalizations.of(context)!.reductions,
                            value: '$negativeTransactions',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Attributes section (grouped by counts)
              Consumer(
                builder: (context, ref, _) {
                  final perScanCountsAsync = ref.watch(perScanAttributeCountsProvider(productId));
                  final onceCountsAsync = ref.watch(onceAttributeCountsProvider(productId));

                  // Combine both async values manually
                  return perScanCountsAsync.when(
                    data: (perScanCounts) {
                      return onceCountsAsync.when(
                        data: (onceCounts) {
                          if (perScanCounts.isEmpty && onceCounts.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Helper to build a list of cards for given map
                          List<Widget> _buildCards(Map<String, Map<String, int>> countsMap, String modeLabel) {
                            return countsMap.entries.map((entry) {
                              final questionId = entry.key;
                              final valueCounts = entry.value;
                              final sortedEntries = valueCounts.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value));
                              final topEntries = sortedEntries.take(3).toList();
                              return FutureBuilder<String>(
                                future: ref.read(scanningVmProvider).getQuestionLabel(questionId),
                                builder: (context, snapshot) {
                                  final label = snapshot.data ?? questionId;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  label,
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  modeLabel,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ...topEntries.map((e) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(child: Text(e.key)),
                                                    Text('${e.value}')
                                                  ],
                                                ),
                                              )),
                                          if (sortedEntries.length > 3)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => AttributeValuesScreen(
                                                        productId: productId,
                                                        questionId: questionId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(AppLocalizations.of(context)!.seeAll),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList();
                          }

                          final l10n = AppLocalizations.of(context)!;
                          return Column(
                            children: [
                              ..._buildCards(perScanCounts, l10n.askModeEveryS),
                              ..._buildCards(onceCounts, l10n.askModeOnce),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(child: Text(error.toString())),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text(error.toString())),
                  );
                },
              ),

              // Photo gallery (reuse existing consumer)
              Consumer(
                builder: (context, ref, child) {
                  final photosAsync = ref.watch(productPhotosProvider(productId));
                  return photosAsync.when(
                    data: (photos) {
                      if (photos.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.photosCount(photos.length),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length,
                                  itemBuilder: (context, index) {
                                    final photoPath = photos[index];
                                    final file = File(photoPath);
                                    final fileExists = file.existsSync();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => _openPhotoViewer(context, photos, index),
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: fileExists
                                                ? Image.file(
                                                    file,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image_not_supported),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                    error: (error, _) => Center(child: Text(error.toString())),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  final List<Transaction> transactions;
  const _TransactionsTab({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noTransactionHistoryYet,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(l10n.scanProductToSeeHistory,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Preload once attributes for the whole product (same for all transactions)
    final productId = transactions.first.productId;
    final onceAttributesAsync = ref.watch(productOnceAttributesProvider(productId));

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isPositive = transaction.quantity > 0;
        final isToday = DateTimeUtils.isToday(transaction.timestamp);

        // Fetch categorized answers for this transaction
        final categorizedAsync =
            ref.watch(categorizedAnswersProvider(transaction.id));

        return categorizedAsync.when(
          data: (categorized) {
            final perScan = categorized['per_scan'] ?? {};

            // Use transaction-specific once attributes if available, otherwise fall back to product-level once attributes
            final once = {
              ...?onceAttributesAsync.maybeWhen(data: (data) => data, orElse: () => null),
              ...categorized['once'] ?? {},
            };

            // Helper widget to build attribute chips
            List<Widget> buildAttributeChips(Map<String, String> map, Color color) {
              final scanningVm = ref.read(scanningVmProvider);
              return map.entries.map((entry) {
                return FutureBuilder<String>(
                  future: scanningVm.getQuestionLabel(entry.key),
                  builder: (context, snapshot) {
                    final label = snapshot.data ?? entry.key;
                    return Container(
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$label: ${entry.value}',
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    );
                  },
                );
              }).toList();
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPositive ? Colors.green : Colors.red,
                    child: Icon(
                        isPositive ? Icons.add : Icons.remove, color: Colors.white),
                  ),
                  title: Text(
                    isToday
                        ? DateTimeUtils.formatTodayAt(
                            context, transaction.timestamp.toLocal())
                        : DateTimeUtils.formatTransactionHistory(
                            context, transaction.timestamp.toLocal()),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _transactionDescription(context, transaction),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      if (perScan.isNotEmpty)
                        Wrap(
                          children:
                              buildAttributeChips(perScan, Theme.of(context).colorScheme.primary),
                        ),
                      if (once.isNotEmpty)
                        Wrap(
                          children:
                              // Use a distinct color to avoid both categories showing the same hue
                              buildAttributeChips(once, Colors.green),
                        ),
                    ],
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
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          error: (error, _) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(title: Text('Error: $error')),
          ),
        );
      },
    );
  }
}

String _transactionDescription(BuildContext context, Transaction transaction) {
  final l10n = AppLocalizations.of(context)!;
  return transaction.quantity > 0 ? l10n.stockAddition : l10n.stockReduction;
}

// Helper to present photo viewer dialog
void _openPhotoViewer(BuildContext context, List<String> photos, int initialIndex) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(AppLocalizations.of(context)!.photoViewerTitle(initialIndex + 1, photos.length)),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photoPath = photos[index];
                  final file = File(photoPath);
                  final fileExists = file.existsSync();
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: fileExists
                          ? Image.file(
                              file,
                              fit: BoxFit.contain,
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 64),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 