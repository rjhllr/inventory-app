import 'package:inventory_app/data/app_database.dart';

abstract class IDataSource {
  // Products
  Future<void> upsertProduct(ProductsCompanion product);
  Stream<List<Product>> watchProducts();
  Stream<List<Product>> watchProductsWithScans();

  // Scans
  Future<void> addScan(ScansCompanion scan);
  Stream<List<Scan>> watchScans();
  Future<void> deleteAllScans();
  Future<void> deleteScansForProduct(String productId);
  
  // Prompt Questions
  Stream<List<PromptQuestion>> watchPromptQuestions();
  Future<void> upsertPromptQuestion(PromptQuestionsCompanion question);
  Future<void> deletePromptQuestion(String id);
 
  // Prompt Answers
  Future<bool> hasAnswerForProduct(String productId, String questionId);
  Future<void> addScanWithAnswers(
      {required ScansCompanion scan,
      required List<PromptAnswersCompanion> answers});
  Future<PromptAnswer?> getLastAnswerForQuestion(String questionId);
} 