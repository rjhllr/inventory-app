import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/data/app_database.dart';
import 'package:inventory_app/providers.dart';

class ResetStocksVm {
  final Ref _ref;

  ResetStocksVm(this._ref);

  Future<void> deleteAllScans() {
    return _ref.read(dataSourceProvider).deleteAllScans();
  }

  Future<void> deleteScansForProduct(String productId) {
    return _ref.read(dataSourceProvider).deleteScansForProduct(productId);
  }
}

final resetStocksVmProvider = Provider.autoDispose((ref) => ResetStocksVm(ref));

final productsWithScansProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(dataSourceProvider).watchProductsWithScans();
}); 