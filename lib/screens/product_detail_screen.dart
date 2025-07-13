import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../view_models/scanning_vm.dart';
import '../providers.dart';

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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No transaction history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan this product to see its transaction history here',
                    style: TextStyle(color: Colors.grey),
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
                        'Stock Summary',
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
                                'Current Stock',
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
                                'Total Transactions',
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
                            label: 'Additions',
                            value: '$positiveTransactions',
                            color: Colors.green,
                          ),
                          _StatChip(
                            icon: Icons.remove,
                            label: 'Reductions',
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
                    'Product Attributes',
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
      
      // Transaction history header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            Text(
              'Transaction History',
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
                    final isToday = _isToday(transaction.timestamp);
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
                            ? 'Today at ${DateFormat.jm().format(transaction.timestamp.toLocal())}'
                            : DateFormat.yMMMd().add_jm().format(transaction.timestamp.toLocal()),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _getTransactionDescription(transaction),
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
              Text('Error loading transaction history: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(productTransactionsStreamProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return date.isAtSameMomentAs(today);
  }
  
  String _getTransactionDescription(Transaction transaction) {
    if (transaction.quantity > 0) {
      return 'Stock addition';
    } else {
      return 'Stock reduction';
    }
  }
  
  void _showProductInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product ID: $productId'),
            const SizedBox(height: 8),
            const Text('This screen shows the complete transaction history for this product.'),
            const SizedBox(height: 8),
            const Text('• Positive quantities represent stock additions'),
            const Text('• Negative quantities represent stock reductions or resets'),
            const Text('• Current stock is the sum of all transactions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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