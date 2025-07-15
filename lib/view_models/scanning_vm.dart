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

  /// Helper method to get "once" attributes for a product
  /// Returns the first answer found for each "once" question for this product
  Future<Map<String, String>> getOnceAttributesForProduct(String productId) async {
    final dataSource = ref.read(dataSourceProvider);
    final questions = await ref.read(promptQuestionsProvider.future);
    final onceQuestions = questions.where((q) => q.askMode == AskMode.once.name).toList();
    
    final onceAttributes = <String, String>{};
    
    for (final question in onceQuestions) {
      // Get the first transaction for this product that has an answer to this question
      final transactions = await dataSource.watchTransactionsForProduct(productId).first;
      
      for (final transaction in transactions.reversed) { // Check oldest first
        final answers = await dataSource.getAnswersMapForTransaction(transaction.id);
        if (answers.containsKey(question.id)) {
          onceAttributes[question.id] = answers[question.id]!;
          break; // Found the answer, move to next question
        }
      }
    }
    
    return onceAttributes;
  }

  /// Helper method to categorize answers by ask mode
  Future<Map<String, Map<String, String>>> categorizeAnswersForTransaction(String transactionId) async {
    final dataSource = ref.read(dataSourceProvider);
    final questions = await ref.read(promptQuestionsProvider.future);
    final answers = await dataSource.getAnswersMapForTransaction(transactionId);
    
    final perScanAnswers = <String, String>{};
    final onceAnswers = <String, String>{};
    
    for (final entry in answers.entries) {
      final question = questions.firstWhere(
        (q) => q.id == entry.key,
        orElse: () => PromptQuestion(
          id: entry.key,
          label: entry.key,
          inputType: 'text',
          askMode: 'once',
          prefillLastInput: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Skip photo answers as they are shown separately in the gallery and
      // the raw file paths are not useful in the transaction list.
      if (question.inputType == 'photo') {
        continue;
      }
      
      if (question.askMode == AskMode.every_scan.name) {
        perScanAnswers[entry.key] = entry.value;
      } else {
        onceAnswers[entry.key] = entry.value;
      }
    }
    
    return {
      'per_scan': perScanAnswers,
      'once': onceAnswers,
    };
  }

  /// Helper method to get question label by ID
  Future<String> getQuestionLabel(String questionId) async {
    final questions = await ref.read(promptQuestionsProvider.future);
    final question = questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => PromptQuestion(
        id: questionId,
        label: questionId,
        inputType: 'text',
        askMode: 'once',
        prefillLastInput: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return question.label;
  }

  /// Helper method to get all photos for a product
  Future<List<String>> getPhotosForProduct(String productId) async {
    final dataSource = ref.read(dataSourceProvider);
    final questions = await ref.read(promptQuestionsProvider.future);
    final photoQuestions = questions.where((q) => q.inputType == 'photo').toList();
    
    if (photoQuestions.isEmpty) {
      return [];
    }
    
    final allPhotos = <String>[];
    
    // Fetch transactions only once, not for each photo question
    final transactions = await dataSource.watchTransactionsForProduct(productId).first;
    
    // Process transactions in chronological order (oldest first)
    for (final transaction in transactions.reversed) {
      final answers = await dataSource.getAnswersMapForTransaction(transaction.id);
      
      // Check each photo question for this transaction
      for (final question in photoQuestions) {
        if (answers.containsKey(question.id)) {
          final photoValue = answers[question.id]!;
          if (photoValue.isNotEmpty) {
            // Photos are stored as comma-separated paths
            final photoPaths = photoValue.split(',');
            for (final photoPath in photoPaths) {
              final trimmedPath = photoPath.trim();
              if (trimmedPath.isNotEmpty && !allPhotos.contains(trimmedPath)) {
                allPhotos.add(trimmedPath);
              }
            }
          }
        }
      }
    }
    
    return allPhotos;
  }

  /// Helper method to get grouped counts for "once" attributes across all transactions of a product
  Future<Map<String, Map<String, int>>> getOnceAttributeValueCountsForProduct(String productId) async {
    final dataSource = ref.read(dataSourceProvider);
    final questions = await ref.read(promptQuestionsProvider.future);
    // Exclude questions of inputType 'photo' as these are handled separately in the gallery.
    final onceQuestionIds = questions
        .where((q) => q.askMode == AskMode.once.name && q.inputType != 'photo')
        .map((q) => q.id)
        .toSet();

    if (onceQuestionIds.isEmpty) {
      return {};
    }

    // Fetch all transactions for the product once
    final transactions = await dataSource.watchTransactionsForProduct(productId).first;

    final Map<String, Map<String, int>> counts = {};

    for (final transaction in transactions) {
      final answers = await dataSource.getAnswersMapForTransaction(transaction.id);
      for (final entry in answers.entries) {
        final questionId = entry.key;
        final value = entry.value;
        if (!onceQuestionIds.contains(questionId)) continue;
        final valueCounts = counts.putIfAbsent(questionId, () => {});
        // Sum the transaction quantities instead of counting occurrences so that the
        // resulting value represents the *quantity* linked to the attribute rather
        // than the number of transactions containing the attribute.
        valueCounts[value] = (valueCounts[value] ?? 0) + transaction.quantity;
      }
    }

    return counts;
  }

  /// Helper method to get grouped counts for "per_scan" (every_scan) attributes across all transactions of a product
  Future<Map<String, Map<String, int>>> getPerScanAttributeValueCountsForProduct(String productId) async {
    final dataSource = ref.read(dataSourceProvider);
    final questions = await ref.read(promptQuestionsProvider.future);

    // Only include every_scan attributes that are NOT photos
    final perScanQuestionIds = questions
        .where((q) => q.askMode == AskMode.every_scan.name && q.inputType != 'photo')
        .map((q) => q.id)
        .toSet();

    if (perScanQuestionIds.isEmpty) {
      return {};
    }

    // Fetch all transactions for the product once
    final transactions = await dataSource.watchTransactionsForProduct(productId).first;

    final Map<String, Map<String, int>> counts = {};

    for (final transaction in transactions) {
      final answers = await dataSource.getAnswersMapForTransaction(transaction.id);
      for (final entry in answers.entries) {
        final questionId = entry.key;
        final value = entry.value;
        if (!perScanQuestionIds.contains(questionId)) continue;
        final valueCounts = counts.putIfAbsent(questionId, () => {});
        // Sum the transaction quantities instead of counting occurrences so that the
        // resulting value represents the *quantity* linked to the attribute rather
        // than the number of individual transactions containing the attribute.
        valueCounts[value] = (valueCounts[value] ?? 0) + transaction.quantity;
      }
    }

    return counts;
  }
}

final scanningVmProvider = Provider<ScanningVm>((ref) => ScanningVm(ref));

final transactionsStreamProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(dataSourceProvider).watchTransactions();
});

final productTransactionsStreamProvider = StreamProvider.autoDispose.family<List<Transaction>, String>((ref, productId) {
  return ref.watch(dataSourceProvider).watchTransactionsForProduct(productId);
});

// Provider for effective count at a specific transaction
final effectiveCountAtTransactionProvider = FutureProvider.autoDispose.family<int, ({String productId, DateTime timestamp})>((ref, params) async {
  final scanningVm = ref.watch(scanningVmProvider);
  return await scanningVm.calculateEffectiveCountAtTransaction(params.productId, params.timestamp);
});

// Provider for categorized answers for a transaction
final categorizedAnswersProvider = FutureProvider.autoDispose.family<Map<String, Map<String, String>>, String>((ref, transactionId) async {
  final scanningVm = ref.watch(scanningVmProvider);
  return await scanningVm.categorizeAnswersForTransaction(transactionId);
});

// Provider for product photos
final productPhotosProvider = FutureProvider.autoDispose.family<List<String>, String>((ref, productId) async {
  final scanningVm = ref.watch(scanningVmProvider);
  return await scanningVm.getPhotosForProduct(productId);
}); 

// Provider for once attribute value counts per product
final onceAttributeCountsProvider = FutureProvider.autoDispose.family<Map<String, Map<String, int>>, String>((ref, productId) async {
  final scanningVm = ref.watch(scanningVmProvider);
  return scanningVm.getOnceAttributeValueCountsForProduct(productId);
}); 

// Provider for per_scan attribute value counts per product
final perScanAttributeCountsProvider = FutureProvider.autoDispose.family<Map<String, Map<String, int>>, String>((ref, productId) async {
  final scanningVm = ref.watch(scanningVmProvider);
  return scanningVm.getPerScanAttributeValueCountsForProduct(productId);
}); 