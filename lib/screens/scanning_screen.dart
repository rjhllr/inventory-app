import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/app_database.dart';
import '../providers.dart';
import '../view_models/scanning_vm.dart';
import '../view_models/settings_vm.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen> {
  bool _pause = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_pause) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Prevent re-scanning
    setState(() => _pause = true);

    final scanningVm = ref.read(scanningVmProvider);
    final settingsVm = ref.read(settingsVmProvider);
    final requiredPrompts = await scanningVm.getPromptsForCode(code);
    final quantityPrompt = settingsVm.isQuantityPromptEnabled;

    if (requiredPrompts.isEmpty && !quantityPrompt) {
      // No prompts needed, just save and continue
      await scanningVm.saveTransaction(code: code, quantity: 1, answers: {});
    } else {
      // Show dialog to collect info
      final results = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: _PromptDialog(
            productCode: code,
            questions: requiredPrompts,
            promptForQuantity: quantityPrompt,
          ),
        ),
      );

      if (results != null) {
        await scanningVm.saveTransaction(
          code: code,
          quantity: results['quantity'] as int,
          answers: results['answers'] as Map<String, String>,
        );
      }
    }

    // Resume scanning after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _pause = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scanning')),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          const Divider(height: 1),
          // Recent transactions list
          Expanded(
            flex: 2,
            child: transactionsAsync.when(
              data: (transactions) => ListView.builder(
                reverse: true,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return ListTile(
                    title: Text(transaction.productId),
                    subtitle: Text(transaction.timestamp.toLocal().toString()),
                    trailing: Text('${transaction.quantity > 0 ? '+' : ''}${transaction.quantity}'),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptDialog extends ConsumerStatefulWidget {
  final String productCode;
  final List<PromptQuestion> questions;
  final bool promptForQuantity;

  const _PromptDialog({
    required this.productCode,
    required this.questions,
    required this.promptForQuantity,
  });

  @override
  ConsumerState<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends ConsumerState<_PromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _answers = {};
  final Map<String, dynamic> _initialValues = {};
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchInitialValues();
  }

  Future<void> _fetchInitialValues() async {
    final dataSource = ref.read(dataSourceProvider);
    for (final q in widget.questions) {
      if (q.prefillLastInput) {
        final lastAnswer = await dataSource.getLastAnswerForQuestion(q.id);
        if (lastAnswer != null) {
          if (q.inputType == 'date') {
            _initialValues[q.id] = DateTime.tryParse(lastAnswer.value);
          } else {
            _initialValues[q.id] = lastAnswer.value;
          }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text('Product: ${widget.productCode}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.promptForQuantity) ...[
                TextFormField(
                  initialValue: _quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => _quantity = int.parse(value!),
                ),
                const SizedBox(height: 16),
              ],
              ...widget.questions.map((question) {
                switch (question.inputType) {
                  case 'number':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        initialValue: _initialValues[question.id]?.toString(),
                        decoration: InputDecoration(labelText: question.label),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onSaved: (value) => _answers[question.id] = value!,
                      ),
                    );
                  case 'text':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        initialValue: _initialValues[question.id]?.toString(),
                        decoration: InputDecoration(labelText: question.label),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          return null;
                        },
                        onSaved: (value) => _answers[question.id] = value!,
                      ),
                    );
                  case 'date':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _DateField(
                        label: question.label,
                        initialValue: _initialValues[question.id] as DateTime?,
                        onSaved: (value) => _answers[question.id] = value!.toIso8601String(),
                      ),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.of(context).pop({
                'quantity': _quantity,
                'answers': _answers,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DateField extends StatefulWidget {
  final String label;
  final DateTime? initialValue;
  final Function(DateTime) onSaved;

  const _DateField({
    required this.label,
    this.initialValue,
    required this.onSaved,
  });

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          widget.onSaved(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat.yMd().format(_selectedDate!)
              : 'Select date',
        ),
      ),
    );
  }
} 