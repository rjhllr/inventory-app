import 'package:inventory_app/data/app_database.dart';

abstract class IDataSource {
  // Products
  Future<void> upsertProduct(ProductsCompanion product);
  Stream<List<Product>> watchProducts();
  Stream<List<Product>> watchProductsWithTransactions();
  Future<void> deleteAllProducts();

  // Transactions
  Future<void> addTransaction(TransactionsCompanion transaction);
  Stream<List<Transaction>> watchTransactions();
  Stream<List<Transaction>> watchTransactionsForProduct(String productId);
  Future<void> deleteAllTransactions();
  Future<void> deleteTransactionsForProduct(String productId);
  Future<void> updateTransactionQuantity(String transactionId, int quantity);
  
  // Prompt Questions
  Stream<List<PromptQuestion>> watchPromptQuestions();
  Future<void> upsertPromptQuestion(PromptQuestionsCompanion question);
  Future<void> deletePromptQuestion(String id);
  Future<void> deleteAllPromptQuestions();
 
  // Prompt Answers
  Future<bool> hasAnswerForProduct(String productId, String questionId);
  Future<void> addTransactionWithAnswers(
      {required TransactionsCompanion transaction,
      required List<PromptAnswersCompanion> answers});
  Future<PromptAnswer?> getLastAnswerForQuestion(String questionId);
  Future<List<PromptAnswer>> getAnswersForTransaction(String transactionId);
  Future<Map<String, String>> getAnswersMapForTransaction(String transactionId);
} 