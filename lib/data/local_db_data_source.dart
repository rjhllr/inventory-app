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
  Stream<List<Product>> watchProductsWithScans() {
    final query = _db.selectOnly(_db.scans, distinct: true)..addColumns([_db.scans.productId]);
    
    return query.watch().asyncMap((results) {
      final productIds = results.map((row) => row.read(_db.scans.productId)).whereType<String>().toList();
      if (productIds.isEmpty) return Future.value([]);
      return (_db.select(_db.products)..where((p) => p.id.isIn(productIds))).get();
    });
  }

  @override
  Future<void> addScan(ScansCompanion scan) async {
    await _db.into(_db.scans).insert(scan);
  }

  @override
  Stream<List<Scan>> watchScans() {
    final query = _db.select(_db.scans)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return query.watch();
  }

  @override
  Future<void> deleteAllScans() {
    return _db.delete(_db.scans).go();
  }

  @override
  Future<void> deleteScansForProduct(String productId) {
    return (_db.delete(_db.scans)..where((t) => t.productId.equals(productId))).go();
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
  Future<bool> hasAnswerForProduct(String productId, String questionId) async {
    final query = _db.select(_db.promptAnswers).join([
      innerJoin(_db.scans, _db.scans.id.equalsExp(_db.promptAnswers.scanId))
    ])
      ..where(_db.scans.productId.equals(productId) &
          _db.promptAnswers.questionId.equals(questionId))
      ..limit(1);

    final result = await query.get();
    return result.isNotEmpty;
  }

  @override
  Future<void> addScanWithAnswers(
      {required ScansCompanion scan,
      required List<PromptAnswersCompanion> answers}) async {
    return _db.transaction(() async {
      await _db.into(_db.scans).insert(scan);
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
} 