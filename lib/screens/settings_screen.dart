import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app/data/app_database.dart';
import 'package:inventory_app/view_models/settings_vm.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsVm = ref.read(settingsVmProvider);
    final questionsAsync = ref.watch(promptQuestionsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockTakingSettings)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SwitchListTile(
              title: Text(l10n.promptForQuantity),
              value: settingsVm.isQuantityPromptEnabled,
              onChanged: (value) async {
                await settingsVm.setQuantityPrompt(value);
                // The UI will automatically rebuild when the state changes
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.additionalPrompts, style: Theme.of(context).textTheme.titleLarge),
                  FilledButton(
                    onPressed: () => _navigateToAddPrompt(context),
                    child: Text(l10n.add),
                  ),
                ],
              ),
            ),
          ),
          questionsAsync.when(
            data: (questions) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final q = questions[index];
                  return ListTile(
                    title: Text(q.label),
                    subtitle: Text('${l10n.type}: ${_translateInputType(q.inputType, l10n)}, ${l10n.mode}: ${_translateAskMode(q.askMode, l10n)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navigateToEditPrompt(context, q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref.read(settingsVmProvider).deleteQuestion(q.id),
                        ),
                      ],
                    ),
                  );
                },
                childCount: questions.length,
              ),
            ),
            loading: () => SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text(l10n.errorMessage(e.toString())))),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPrompt(BuildContext context) {
    context.pushNamed('add-prompt');
  }

  void _navigateToEditPrompt(BuildContext context, PromptQuestion question) {
    context.pushNamed('add-prompt', extra: question);
  }

  String _translateInputType(String inputType, AppLocalizations l10n) {
    switch (inputType) {
      case 'text':
        return l10n.inputTypeText;
      case 'number':
        return l10n.inputTypeNumber;
      case 'photo':
        return l10n.inputTypePhoto;
      case 'date':
        return l10n.inputTypeDate;
      default:
        return inputType;
    }
  }

  String _translateAskMode(String askMode, AppLocalizations l10n) {
    switch (askMode) {
      case 'once':
        return l10n.askModeOnce;
      case 'every_scan':
        return l10n.askModeEveryS;
      default:
        return askMode.replaceAll('_', ' ');
    }
  }
}

 