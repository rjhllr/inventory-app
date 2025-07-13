import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../providers.dart';
import '../data/app_database.dart';
import 'settings_vm.dart';

class ScanningVm {
  ScanningVm(this.ref);

  final Ref ref;
  final _uuid = const Uuid();

  Future<void> handleBarcode(String code, {int quantity = 1}) async {
    final dataSource = ref.read(dataSourceProvider);

    // Ensure product exists (upsert)
    await dataSource.upsertProduct(ProductsCompanion(
      id: Value(code),
      attributesJson: const Value(null),
    ));

    // Add transaction entry
    final transactionId = _uuid.v4();
    await dataSource.addTransaction(TransactionsCompanion(
      id: Value(transactionId),
      productId: Value(code),
      quantity: Value(quantity),
    ));
  }

  Future<List<PromptQuestion>> getPromptsForCode(String code) async {
    final dataSource = ref.read(dataSourceProvider);
    final questions = await ref.read(promptQuestionsProvider.future);
    final prompts = <PromptQuestion>[];

    for (final question in questions) {
      if (question.askMode == AskMode.every_scan.name) {
        prompts.add(question);
      } else {
        final hasAnswer = await dataSource.hasAnswerForProduct(code, question.id);
        if (!hasAnswer) {
          prompts.add(question);
        }
      }
    }
    return prompts;
  }

  Future<void> saveTransaction({
    required String code,
    required int quantity,
    required Map<String, String> answers,
  }) async {
    final dataSource = ref.read(dataSourceProvider);
    final transactionId = _uuid.v4();
    
    // Ensure product exists (upsert)
    await dataSource.upsertProduct(ProductsCompanion(
      id: Value(code),
      attributesJson: const Value(null),
    ));
    
    final transaction = TransactionsCompanion(
      id: Value(transactionId),
      productId: Value(code),
      quantity: Value(quantity),
    );

    final answerCompanions = answers.entries.map((entry) {
      return PromptAnswersCompanion(
        id: Value(_uuid.v4()),
        transactionId: Value(transactionId),
        questionId: Value(entry.key),
        value: Value(entry.value),
      );
    }).toList();

    await dataSource.addTransactionWithAnswers(
      transaction: transaction,
      answers: answerCompanions,
    );
  }

  Future<int> calculateEffectiveCountAtTransaction(String productId, DateTime timestamp) async {
    final dataSource = ref.read(dataSourceProvider);
    final transactions = await dataSource.watchTransactionsForProduct(productId).first;
    
    // Get all transactions up to and including the specified timestamp
    final relevantTransactions = transactions.where((t) => t.timestamp.isBefore(timestamp) || t.timestamp.isAtSameMomentAs(timestamp)).toList();
    
    // Calculate sum of quantities
    return relevantTransactions.fold<int>(0, (sum, transaction) => sum + transaction.quantity);
  }

  Future<void> updateTransactionQuantity(String transactionId, int quantity) async {
    final dataSource = ref.read(dataSourceProvider);
    await dataSource.updateTransactionQuantity(transactionId, quantity);
  }

  Future<void> addQuantityToTransaction(String transactionId, int deltaQuantity) async {
    final dataSource = ref.read(dataSourceProvider);
    final transactions = await dataSource.watchTransactions().first;
    final transaction = transactions.firstWhere((t) => t.id == transactionId);
    final newQuantity = transaction.quantity + deltaQuantity;
    await dataSource.updateTransactionQuantity(transactionId, newQuantity);
  }

  Future<Map<String, String>> getTransactionAnswers(String transactionId) async {
    final dataSource = ref.read(dataSourceProvider);
    return await dataSource.getAnswersMapForTransaction(transactionId);
  }
}

final scanningVmProvider = Provider<ScanningVm>((ref) => ScanningVm(ref));

final transactionsStreamProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(dataSourceProvider).watchTransactions();
});

final productTransactionsStreamProvider = StreamProvider.autoDispose.family<List<Transaction>, String>((ref, productId) {
  return ref.watch(dataSourceProvider).watchTransactionsForProduct(productId);
}); 