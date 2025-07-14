import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:inventory_app/view_models/product_db_vm.dart';
import '../l10n/app_localizations.dart';
import '../datetime_utils.dart';

class ProductDbScreen extends ConsumerWidget {
  const ProductDbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productDatabase)),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(child: Text(l10n.noProductsScannedYet));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.id),
                subtitle: Text(l10n.lastUpdated(DateTimeUtils.formatLastUpdated(context, product.updatedAt.toLocal()))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/products/${Uri.encodeComponent(product.id)}'),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorMessage(e.toString()))),
      ),
    );
  }
} 