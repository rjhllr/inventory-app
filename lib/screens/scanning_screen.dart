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
      await scanningVm.saveScan(code: code, quantity: 1, answers: {});
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
        await scanningVm.saveScan(
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
    final scansAsync = ref.watch(scansStreamProvider);

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
          // Recent scans list
          Expanded(
            flex: 2,
            child: scansAsync.when(
              data: (scans) => ListView.builder(
                reverse: true,
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  return ListTile(
                    title: Text(scan.productId),
                    subtitle: Text(scan.timestamp.toLocal().toString()),
                    trailing: Text('x${scan.quantity}'),
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
        content: Center(child: CircularProgressIndicator()),
      );
    }

    return AlertDialog(
      title: Text('Data for ${widget.productCode}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.promptForQuantity)
                TextFormField(
                  initialValue: '1',
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v == null || v.isEmpty || int.parse(v) < 1
                      ? 'Must be > 0'
                      : null,
                  onSaved: (v) => _quantity = int.parse(v!),
                ),
              ...widget.questions.map(
                (q) {
                  if (q.inputType == 'date') {
                    return _DatePickerField(
                      label: q.label,
                      initialValue: _initialValues[q.id] as DateTime?,
                      onSaved: (date) {
                        if (date != null) {
                          _answers[q.id] = date.toIso8601String();
                        }
                      },
                      validator: (date) => date == null ? 'Required' : null,
                    );
                  }
                  return TextFormField(
                    initialValue: _initialValues[q.id] as String?,
                    decoration: InputDecoration(labelText: q.label),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _answers[q.id] = v!,
                    keyboardType: q.inputType == 'number'
                        ? TextInputType.number
                        : TextInputType.text,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
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

class _DatePickerField extends FormField<DateTime> {
  _DatePickerField({
    Key? key,
    required String label,
    required FormFieldSetter<DateTime> onSaved,
    FormFieldValidator<DateTime>? validator,
    DateTime? initialValue,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue,
          builder: (FormFieldState<DateTime> state) {
            return InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: state.context,
                  initialDate: state.value ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  state.didChange(picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  errorText: state.errorText,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      state.value != null
                          ? DateFormat.yMd().format(state.value!)
                          : 'Select date',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            );
          },
        );
} 