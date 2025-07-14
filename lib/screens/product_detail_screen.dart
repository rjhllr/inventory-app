import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../data/app_database.dart';
import '../view_models/scanning_vm.dart';
import '../l10n/app_localizations.dart';
import '../datetime_utils.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(productTransactionsStreamProvider(productId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(productId),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showProductInfo(context),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTransactionHistoryYet,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.scanProductToSeeHistory,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          final totalQuantity = transactions.fold<int>(0, (sum, transaction) => sum + transaction.quantity);
          final totalTransactions = transactions.length;
          final positiveTransactions = transactions.where((t) => t.quantity > 0).length;
          final negativeTransactions = transactions.where((t) => t.quantity < 0).length;
          
          return Column(
            children: [
              // Summary card
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
      
      // "Once" attributes section
      FutureBuilder<Map<String, String>>(
        future: ref.read(scanningVmProvider).getOnceAttributesForProduct(productId),
        builder: (context, snapshot) {
          final onceAttributes = snapshot.data ?? {};
          
          if (onceAttributes.isEmpty) {
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
                    AppLocalizations.of(context)!.productAttributes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...onceAttributes.entries.map((entry) {
                    return FutureBuilder<String>(
                      future: ref.read(scanningVmProvider).getQuestionLabel(entry.key),
                      builder: (context, labelSnapshot) {
                        final label = labelSnapshot.data ?? entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '$label:',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),

      // Photo gallery section
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
                                onTap: () => _showPhotoViewer(context, photos, index),
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
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
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
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  AppLocalizations.of(context)!.fileNotFound,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
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
            loading: () => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.photos),
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            error: (error, stackTrace) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.photos,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.errorLoadingPhotos(error.toString()),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
              ),
            ),
          );
        },
      ),
      
      // Transaction history header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.transactionHistoryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
              
              // Transaction history list
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isToday = DateTimeUtils.isToday(transaction.timestamp);
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
                          isToday 
                            ? DateTimeUtils.formatTodayAt(context, transaction.timestamp.toLocal())
                            : DateTimeUtils.formatTransactionHistory(context, transaction.timestamp.toLocal()),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _getTransactionDescription(context, transaction),
                          style: TextStyle(color: Colors.grey[600]),
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
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.errorLoadingTransactionHistory(e.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(productTransactionsStreamProvider(productId)),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
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