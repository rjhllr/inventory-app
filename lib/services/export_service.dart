import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../data/i_data_source.dart';

class ExportService {
  final IDataSource _dataSource;

  ExportService(this._dataSource);

  Future<void> exportToZip() async {
    try {
      // Get all data from database
      final products = await _dataSource.watchProducts().first;
      final transactions = await _dataSource.watchTransactions().first;
      final promptQuestions = await _dataSource.watchPromptQuestions().first;

      // Create the ZIP archive
      final archive = Archive();

      // Generate and add products CSV
      final productsCSV = await _generateProductsCSV(products, promptQuestions);
      archive.addFile(ArchiveFile('products.csv', productsCSV.length, productsCSV));

      // Generate and add transactions CSV
      final transactionsCSV = await _generateTransactionsCSV(transactions, promptQuestions);
      archive.addFile(ArchiveFile('transactions.csv', transactionsCSV.length, transactionsCSV));

      // Add images to archive
      await _addImagesToArchive(archive, transactions, promptQuestions);

      // Save ZIP file
      final zipData = ZipEncoder().encode(archive)!;
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipFile = File(path.join(tempDir.path, 'inventory_export_$timestamp.zip'));
      await zipFile.writeAsBytes(zipData);

      // Share the ZIP file
      await Share.shareXFiles([XFile(zipFile.path)], text: 'Inventory Export');

    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> _generateProductsCSV(List<Product> products, List<PromptQuestion> promptQuestions) async {
    final List<List<String>> csvData = [];
    
    // Create header row
    final headers = ['Product ID', 'Created At', 'Updated At'];
    final onceQuestions = promptQuestions.where((q) => q.askMode == 'once').toList();
    for (final question in onceQuestions) {
      headers.add(question.label);
    }
    csvData.add(headers);

    // Add data rows
    for (final product in products) {
      final row = [
        product.id,
        product.createdAt.toIso8601String(),
        product.updatedAt.toIso8601String(),
      ];

      // Add "once" question values for this product
      for (final question in onceQuestions) {
        final value = await _getOnceAnswerForProduct(product.id, question.id);
        row.add(value ?? '');
      }

      csvData.add(row);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(csvString.codeUnits);
  }

  Future<Uint8List> _generateTransactionsCSV(List<Transaction> transactions, List<PromptQuestion> promptQuestions) async {
    final List<List<String>> csvData = [];
    
    // Create header row
    final headers = ['Transaction ID', 'Product ID', 'Quantity', 'Timestamp', 'Created At', 'Updated At'];
    
    // Add all prompt questions as columns
    for (final question in promptQuestions) {
      headers.add('${question.label} (${question.askMode})');
    }
    csvData.add(headers);

    // Add data rows
    for (final transaction in transactions) {
      final row = [
        transaction.id,
        transaction.productId,
        transaction.quantity.toString(),
        transaction.timestamp.toIso8601String(),
        transaction.createdAt.toIso8601String(),
        transaction.updatedAt.toIso8601String(),
      ];

      // Add prompt answers for this transaction
      final answers = await _dataSource.getAnswersMapForTransaction(transaction.id);
      for (final question in promptQuestions) {
        final value = answers[question.id] ?? '';
        
        // For photo questions, convert paths to local references
        if (question.inputType == 'photo' && value.isNotEmpty) {
          final photoPaths = value.split(',');
          final localPaths = photoPaths.map((p) => 'images/${path.basename(p)}').join(',');
          row.add(localPaths);
        } else {
          row.add(value);
        }
      }

      csvData.add(row);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(csvString.codeUnits);
  }

  Future<String?> _getOnceAnswerForProduct(String productId, String questionId) async {
    // Get all transactions for this product
    final transactions = await _dataSource.watchTransactionsForProduct(productId).first;
    
    // Look for the first answer to this "once" question
    for (final transaction in transactions.reversed) { // Check oldest first
      final answers = await _dataSource.getAnswersMapForTransaction(transaction.id);
      if (answers.containsKey(questionId)) {
        final value = answers[questionId]!;
        
        // For photo questions, convert paths to local references
        final question = await _getQuestionById(questionId);
        if (question?.inputType == 'photo' && value.isNotEmpty) {
          final photoPaths = value.split(',');
          final localPaths = photoPaths.map((p) => 'images/${path.basename(p)}').join(',');
          return localPaths;
        }
        
        return value;
      }
    }
    
    return null;
  }

  Future<PromptQuestion?> _getQuestionById(String questionId) async {
    final questions = await _dataSource.watchPromptQuestions().first;
    try {
      return questions.firstWhere((q) => q.id == questionId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _addImagesToArchive(Archive archive, List<Transaction> transactions, List<PromptQuestion> promptQuestions) async {
    final photoQuestions = promptQuestions.where((q) => q.inputType == 'photo').toList();
    final processedImages = <String>{};

    for (final question in photoQuestions) {
      for (final transaction in transactions) {
        final answers = await _dataSource.getAnswersMapForTransaction(transaction.id);
        final photoValue = answers[question.id];
        
        if (photoValue != null && photoValue.isNotEmpty) {
          final photoPaths = photoValue.split(',');
          
          for (final photoPath in photoPaths) {
            if (processedImages.contains(photoPath)) continue;
            
            final file = File(photoPath);
            if (await file.exists()) {
              final imageData = await file.readAsBytes();
              final fileName = path.basename(photoPath);
              archive.addFile(ArchiveFile('images/$fileName', imageData.length, imageData));
              processedImages.add(photoPath);
            }
          }
        }
      }
    }
  }
} 