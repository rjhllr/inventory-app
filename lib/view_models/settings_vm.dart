import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../data/app_database.dart';
import '../providers.dart';

enum InputType { number, text, photo, date }

enum AskMode { once, every_scan }

class SettingsVm {
  final Ref _ref;
  final _uuid = const Uuid();
  static const promptQuantityKey = 'promptQuantity';

  SettingsVm(this._ref);

  SharedPreferences get _prefs => _ref.read(sharedPrefsProvider);
  
  bool get isQuantityPromptEnabled => _prefs.getBool(promptQuantityKey) ?? false;

  Future<void> setQuantityPrompt(bool value) async {
    await _prefs.setBool(promptQuantityKey, value);
  }

  Future<void> saveQuestion({
    String? id,
    required String label,
    required InputType inputType,
    required AskMode askMode,
    required bool prefillLastInput,
  }) {
    final question = PromptQuestionsCompanion(
      id: Value(id ?? _uuid.v4()),
      label: Value(label),
      inputType: Value(inputType.name),
      askMode: Value(askMode.name),
      prefillLastInput: Value(prefillLastInput),
    );
    return _ref.read(dataSourceProvider).upsertPromptQuestion(question);
  }

  Future<void> deleteQuestion(String id) {
    return _ref.read(dataSourceProvider).deletePromptQuestion(id);
  }
}

final settingsVmProvider = Provider.autoDispose((ref) => SettingsVm(ref));

final promptQuestionsProvider = StreamProvider.autoDispose<List<PromptQuestion>>((ref) {
  return ref.watch(dataSourceProvider).watchPromptQuestions();
}); 