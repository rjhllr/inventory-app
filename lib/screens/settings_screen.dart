import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app/data/app_database.dart';
import 'package:inventory_app/view_models/settings_vm.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsVm = ref.read(settingsVmProvider);
    final questionsAsync = ref.watch(promptQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock-taking Settings')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SwitchListTile(
              title: const Text('Prompt for Quantity'),
              value: settingsVm.isQuantityPromptEnabled,
              onChanged: (value) async {
                await settingsVm.setQuantityPrompt(value);
                // Rebuild to reflect change
                (context as Element).reassemble();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Additional Prompts', style: Theme.of(context).textTheme.titleLarge),
                  FilledButton(
                    onPressed: () => _navigateToAddPrompt(context),
                    child: const Text('Add'),
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
                    subtitle: Text('Type: ${q.inputType}, Mode: ${q.askMode.replaceAll('_', ' ')}'),
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
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
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
}

 