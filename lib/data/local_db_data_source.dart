import 'package:drift/drift.dart';
import 'package:inventory_app/data/app_database.dart';

import 'i_data_source.dart';

class LocalDbDataSource implements IDataSource {
  final AppDatabase _db;

  LocalDbDataSource(this._db);

  @override
  Future<void> upsertProduct(ProductsCompanion product) async {
    await _db.into(_db.products).insertOnConflictUpdate(product);
  }

  @override
  Stream<List<Product>> watchProducts() {
    return _db.select(_db.products).watch();
  }

  @override
  Stream<List<Product>> watchProductsWithTransactions() {
    final query = _db.selectOnly(_db.transactions, distinct: true)..addColumns([_db.transactions.productId]);
    
    return query.watch().asyncMap((results) {
      final productIds = results.map((row) => row.read(_db.transactions.productId)).whereType<String>().toList();
      if (productIds.isEmpty) return Future.value([]);
      return (_db.select(_db.products)..where((p) => p.id.isIn(productIds))).get();
    });
  }

  @override
  Future<void> deleteAllProducts() {
    return _db.delete(_db.products).go();
  }

  @override
  Future<void> addTransaction(TransactionsCompanion transaction) async {
    await _db.into(_db.transactions).insert(transaction);
  }

  @override
  Stream<List<Transaction>> watchTransactions() {
    final query = _db.select(_db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return query.watch();
  }

  @override
  Stream<List<Transaction>> watchTransactionsForProduct(String productId) {
    final query = _db.select(_db.transactions)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return query.watch();
  }

  @override
  Future<void> deleteAllTransactions() {
    return _db.delete(_db.transactions).go();
  }

  @override
  Future<void> deleteTransactionsForProduct(String productId) {
    return (_db.delete(_db.transactions)..where((t) => t.productId.equals(productId))).go();
  }

  @override
  Future<void> updateTransactionQuantity(String transactionId, int quantity) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
        .write(TransactionsCompanion(quantity: Value(quantity)));
  }

  @override
  Stream<List<PromptQuestion>> watchPromptQuestions() {
    final query = _db.select(_db.promptQuestions)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  @override
  Future<void> upsertPromptQuestion(PromptQuestionsCompanion question) {
    return _db.into(_db.promptQuestions).insertOnConflictUpdate(question);
  }

  @override
  Future<void> deletePromptQuestion(String id) {
    return (_db.delete(_db.promptQuestions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteAllPromptQuestions() {
    return _db.delete(_db.promptQuestions).go();
  }

  @override
  Future<bool> hasAnswerForProduct(String productId, String questionId) async {
    final query = _db.select(_db.promptAnswers).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.promptAnswers.transactionId))
    ])
      ..where(_db.transactions.productId.equals(productId) &
          _db.promptAnswers.questionId.equals(questionId))
      ..limit(1);

    final result = await query.get();
    return result.isNotEmpty;
  }

  @override
  Future<void> addTransactionWithAnswers(
      {required TransactionsCompanion transaction,
      required List<PromptAnswersCompanion> answers}) async {
    return _db.transaction(() async {
      await _db.into(_db.transactions).insert(transaction);
      for (final answer in answers) {
        await _db.into(_db.promptAnswers).insert(answer);
      }
    });
  }

  @override
  Future<PromptAnswer?> getLastAnswerForQuestion(String questionId) async {
    final query = _db.select(_db.promptAnswers)
      ..where((t) => t.questionId.equals(questionId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  @override
  Future<List<PromptAnswer>> getAnswersForTransaction(String transactionId) async {
    final query = _db.select(_db.promptAnswers)
      ..where((t) => t.transactionId.equals(transactionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return await query.get();
  }

  @override
  Future<Map<String, String>> getAnswersMapForTransaction(String transactionId) async {
    final answers = await getAnswersForTransaction(transactionId);
    final answerMap = <String, String>{};
    for (final answer in answers) {
      answerMap[answer.questionId] = answer.value;
    }
    return answerMap;
  }
} 