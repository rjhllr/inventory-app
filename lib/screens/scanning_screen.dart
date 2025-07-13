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
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _debounceDuration = Duration(seconds: 2);

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_pause) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Debounce: Check if this is the same code as last time
    final now = DateTime.now();
    if (_lastScannedCode == code && _lastScanTime != null) {
      final timeSinceLastScan = now.difference(_lastScanTime!);
      if (timeSinceLastScan < _debounceDuration) {
        // Same code within debounce period, ignore
        return;
      }
    }

    // Update last scanned code and time
    _lastScannedCode = code;
    _lastScanTime = now;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Prevent re-scanning
    setState(() => _pause = true);

    final scanningVm = ref.read(scanningVmProvider);
    final settingsVm = ref.read(settingsVmProvider);
    final contextForDialog = context;
    final requiredPrompts = await scanningVm.getPromptsForCode(code);
    final quantityPrompt = settingsVm.isQuantityPromptEnabled;

    if (requiredPrompts.isEmpty && !quantityPrompt) {
      // No prompts needed, just save and continue
      await scanningVm.saveTransaction(code: code, quantity: 1, answers: {});
    } else {
      // Show dialog to collect info
      if (!mounted) return;
      final results = await showDialog<Map<String, dynamic>>(
        context: contextForDialog,
        barrierDismissible: false,
        builder: (_) => ProviderScope(
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

  Future<void> _showTransactionPreview(Transaction transaction) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => ProviderScope(
        child: _TransactionPreviewDialog(transaction: transaction),
      ),
    );
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
                  return _TransactionTile(
                    transaction: transaction,
                    onTap: () => _showTransactionPreview(transaction),
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

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        ref.read(scanningVmProvider).calculateEffectiveCountAtTransaction(
          transaction.productId,
          transaction.timestamp,
        ),
        ref.read(scanningVmProvider).categorizeAnswersForTransaction(transaction.id),
      ]),
      builder: (context, snapshot) {
        final effectiveCount = snapshot.data?[0] ?? 0;
        final categorizedAnswers = snapshot.data?[1] as Map<String, Map<String, String>>? ?? {};
        
        final perScanAnswers = categorizedAnswers['per_scan'] ?? {};
        final onceAnswers = categorizedAnswers['once'] ?? {};
        
        final isPositive = effectiveCount > 0;
        final isNegative = effectiveCount < 0;

        return ListTile(
          onTap: onTap,
          title: Text(transaction.productId),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.timestamp.toLocal().toString()),
              // Show per-scan attributes
              if (perScanAnswers.isNotEmpty) ...[
                const SizedBox(height: 4),
                FutureBuilder<List<String>>(
                  future: Future.wait(perScanAnswers.entries.map((entry) async {
                    final label = await ref.read(scanningVmProvider).getQuestionLabel(entry.key);
                    return '$label: ${entry.value}';
                  })),
                  builder: (context, attrSnapshot) {
                    if (attrSnapshot.hasData) {
                      return Text(
                        attrSnapshot.data!.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
              // Show "once" attributes with small text for subsequent scans
              if (onceAnswers.isNotEmpty) ...[
                const SizedBox(height: 4),
                FutureBuilder<List<String>>(
                  future: Future.wait(onceAnswers.entries.map((entry) async {
                    final label = await ref.read(scanningVmProvider).getQuestionLabel(entry.key);
                    return '$label: ${entry.value}';
                  })),
                  builder: (context, attrSnapshot) {
                    if (attrSnapshot.hasData) {
                      return Text(
                        attrSnapshot.data!.join(', '),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${transaction.quantity > 0 ? '+' : ''}${transaction.quantity}'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : isNegative
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  effectiveCount.toString(),
                  style: TextStyle(
                    color: isPositive
                        ? Colors.green
                        : isNegative
                            ? Colors.red
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionPreviewDialog extends ConsumerStatefulWidget {
  final Transaction transaction;

  const _TransactionPreviewDialog({required this.transaction});

  @override
  ConsumerState<_TransactionPreviewDialog> createState() => _TransactionPreviewDialogState();
}

class _TransactionPreviewDialogState extends ConsumerState<_TransactionPreviewDialog> {
  late TextEditingController _totalCountController;
  Map<String, String> _answers = {};
  List<PromptQuestion> _questions = [];
  bool _isLoading = true;
  int _currentEffectiveCount = 0;

  @override
  void initState() {
    super.initState();
    _totalCountController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _totalCountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final scanningVm = ref.read(scanningVmProvider);
    final answers = await scanningVm.getTransactionAnswers(widget.transaction.id);
    final questions = await ref.read(promptQuestionsProvider.future);
    final effectiveCount = await scanningVm.calculateEffectiveCountAtTransaction(
      widget.transaction.productId,
      widget.transaction.timestamp,
    );
    
    setState(() {
      _answers = answers;
      _questions = questions;
      _currentEffectiveCount = effectiveCount;
      _totalCountController.text = effectiveCount.toString();
      _isLoading = false;
    });
  }

  Future<void> _setNewTotal() async {
    final newTotal = int.tryParse(_totalCountController.text);
    if (newTotal == null) return;
    
    final difference = newTotal - _currentEffectiveCount;
    if (difference == 0) return;
    
    final scanningVm = ref.read(scanningVmProvider);
    
    // Create a corrective transaction
    await scanningVm.saveTransaction(
      code: widget.transaction.productId,
      quantity: difference,
      answers: {},
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total count set to $newTotal (${difference > 0 ? '+' : ''}$difference)'),
          backgroundColor: difference > 0 ? Colors.green : Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
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

    final isPositive = _currentEffectiveCount > 0;
    final isNegative = _currentEffectiveCount < 0;

    return AlertDialog(
      title: const Text('Transaction Details'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            _InfoRow(label: 'Product', value: widget.transaction.productId),
            _InfoRow(
              label: 'Timestamp',
              value: DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.transaction.timestamp.toLocal()),
            ),
            _InfoRow(label: 'This Transaction', value: '${widget.transaction.quantity > 0 ? '+' : ''}${widget.transaction.quantity}'),
            
            // Current effective count
            _InfoRow(
              label: 'Current Total',
              value: _currentEffectiveCount.toString(),
              valueColor: isPositive
                  ? Colors.green
                  : isNegative
                      ? Colors.red
                      : Colors.grey,
            ),
            
            const SizedBox(height: 20),
            
            // Set new total section
            const Text('Set New Total Count:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Total Count',
                      hintText: 'Enter desired total',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _setNewTotal,
                  child: const Text('Set'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Attributes
            if (_answers.isNotEmpty) ...[
              const Text('Attributes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._answers.entries.map((entry) {
                final question = _questions.firstWhere(
                  (q) => q.id == entry.key,
                  orElse: () => PromptQuestion(
                    id: entry.key,
                    label: entry.key,
                    inputType: 'text',
                    askMode: 'once',
                    prefillLastInput: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                return _InfoRow(
                  label: question.label,
                  value: entry.value,
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
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
                  onSaved: (value) => _quantity = int.parse(value ?? '1'),
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
                        onSaved: (value) => _answers[question.id] = value ?? '',
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
                        onSaved: (value) => _answers[question.id] = value ?? '',
                      ),
                    );
                  case 'date':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _DateField(
                        label: question.label,
                        initialValue: _initialValues[question.id] as DateTime?,
                        onSaved: (value) => _answers[question.id] = value.toIso8601String(),
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