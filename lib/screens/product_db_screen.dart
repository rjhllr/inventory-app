import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:inventory_app/view_models/product_db_vm.dart';

class ProductDbScreen extends ConsumerWidget {
  const ProductDbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Product Database')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products scanned yet.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.id),
                subtitle: Text('Last updated: ${DateFormat.yMd().add_jms().format(product.updatedAt.toLocal())}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/products/${product.id}'),
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