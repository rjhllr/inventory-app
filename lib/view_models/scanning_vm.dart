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

    // Add scan entry
    final scanId = _uuid.v4();
    await dataSource.addScan(ScansCompanion(
      id: Value(scanId),
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

  Future<void> saveScan({
    required String code,
    required int quantity,
    required Map<String, String> answers,
  }) async {
    final dataSource = ref.read(dataSourceProvider);
    final scanId = _uuid.v4();
    
    // Ensure product exists (upsert)
    await dataSource.upsertProduct(ProductsCompanion(
      id: Value(code),
      attributesJson: const Value(null),
    ));
    
    final scan = ScansCompanion(
      id: Value(scanId),
      productId: Value(code),
      quantity: Value(quantity),
    );

    final answerCompanions = answers.entries.map((entry) {
      return PromptAnswersCompanion(
        id: Value(_uuid.v4()),
        scanId: Value(scanId),
        questionId: Value(entry.key),
        value: Value(entry.value),
      );
    }).toList();

    await dataSource.addScanWithAnswers(
      scan: scan,
      answers: answerCompanions,
    );
  }
}

final scanningVmProvider = Provider<ScanningVm>((ref) => ScanningVm(ref));

final scansStreamProvider = StreamProvider.autoDispose<List<Scan>>((ref) {
  return ref.watch(dataSourceProvider).watchScans();
}); 