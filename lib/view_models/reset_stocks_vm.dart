import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/data/app_database.dart';
import 'package:inventory_app/providers.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

class ResetStocksVm {
  final Ref _ref;
  final _uuid = const Uuid();

  ResetStocksVm(this._ref);

  Future<void> resetAllStocks() async {
    final dataSource = _ref.read(dataSourceProvider);
    final products = await dataSource.watchProductsWithTransactions().first;
    
    for (final product in products) {
      await _resetStockForProduct(product.id);
    }
  }

  Future<void> resetStockForProduct(String productId) async {
    await _resetStockForProduct(productId);
  }

  Future<void> _resetStockForProduct(String productId) async {
    final dataSource = _ref.read(dataSourceProvider);
    
    // Calculate current effective quantity for the product
    final transactions = await dataSource.watchTransactionsForProduct(productId).first;
    final currentQuantity = transactions.fold<int>(0, (sum, transaction) => sum + transaction.quantity);
    
    // Only create a reset transaction if there's a quantity to reset
    if (currentQuantity != 0) {
      final resetTransaction = TransactionsCompanion(
        id: Value(_uuid.v4()),
        productId: Value(productId),
        quantity: Value(-currentQuantity), // Negative quantity to bring stock to 0
      );
      
      await dataSource.addTransaction(resetTransaction);
    }
  }

  // Legacy method that now creates negative transactions instead of deleting
  Future<void> deleteAllScans() async {
    await resetAllStocks();
  }

  // Legacy method that now creates negative transactions instead of deleting
  Future<void> deleteScansForProduct(String productId) async {
    await resetStockForProduct(productId);
  }
}

final resetStocksVmProvider = Provider.autoDispose((ref) => ResetStocksVm(ref));

final productsWithTransactionsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(dataSourceProvider).watchProductsWithTransactions();
}); 