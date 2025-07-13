import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/data/app_database.dart';
import 'package:inventory_app/providers.dart';

final productsStreamProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final query = ref.watch(dataSourceProvider).watchProductsWithScans();
  return query;
}); 