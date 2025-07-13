import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    onPressed: () => _showQuestionDialog(context, ref),
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
                          onPressed: () => _showQuestionDialog(context, ref, question: q),
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

  void _showQuestionDialog(BuildContext context, WidgetRef ref, {PromptQuestion? question}) {
    showDialog(
      context: context,
      builder: (_) => _QuestionDialog(question: question),
    );
  }
}

class _QuestionDialog extends ConsumerStatefulWidget {
  final PromptQuestion? question;
  const _QuestionDialog({this.question});

  @override
  ConsumerState<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends ConsumerState<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  InputType _inputType = InputType.text;
  AskMode _askMode = AskMode.every_scan;
  bool _prefillLastInput = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _labelController = TextEditingController(text: q?.label ?? '');
    if (q != null) {
      _inputType = InputType.values.firstWhere((e) => e.name == q.inputType);
      _askMode = AskMode.values.firstWhere((e) => e.name == q.askMode);
      _prefillLastInput = q.prefillLastInput;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Prompt' : 'Edit Prompt'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            DropdownButtonFormField<InputType>(
              value: _inputType,
              decoration: const InputDecoration(labelText: 'Input Type'),
              onChanged: (v) => setState(() => _inputType = v!),
              items: InputType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
            ),
            DropdownButtonFormField<AskMode>(
              value: _askMode,
              decoration: const InputDecoration(labelText: 'Ask Mode'),
              onChanged: (v) => setState(() => _askMode = v!),
              items: AskMode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name.replaceAll('_', ' '))))
                  .toList(),
            ),
            SwitchListTile(
              title: const Text('Prefill last input'),
              value: _prefillLastInput,
              onChanged: (v) => setState(() => _prefillLastInput = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(settingsVmProvider).saveQuestion(
                    id: widget.question?.id,
                    label: _labelController.text,
                    inputType: _inputType,
                    askMode: _askMode,
                    prefillLastInput: _prefillLastInput,
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        )
      ],
    );
  }
} 