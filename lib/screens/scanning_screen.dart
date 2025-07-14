import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../datetime_utils.dart';

import '../data/app_database.dart';
import '../view_models/scanning_vm.dart';
import '../view_models/settings_vm.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen> {
  late MobileScannerController _controller;
  bool _pause = false;
  bool _isFlashOn = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _debounceDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      torchEnabled: _isFlashOn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _controller.toggleTorch();
  }

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
    final requiredPrompts = await scanningVm.getPromptsForCode(code);
    final quantityPrompt = settingsVm.isQuantityPromptEnabled;

    if (requiredPrompts.isEmpty && !quantityPrompt) {
      // No prompts needed, just save and continue
      await scanningVm.saveTransaction(code: code, quantity: 1, answers: {});
    } else {
      // Navigate to prompt screen to collect info
      if (!mounted) return;
      await context.pushNamed(
        'prompt',
        extra: {
          'productCode': code,
          'questions': requiredPrompts,
          'promptForQuantity': quantityPrompt,
        },
      );

      // If the user completed the prompts, no need to do anything
      // as the prompt screen handles saving
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanning),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : null,
            ),
            onPressed: _toggleFlash,
            tooltip: _isFlashOn ? l10n.turnOffFlash : l10n.turnOnFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _controller,
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
              error: (e, _) => Center(child: Text(l10n.errorMessage(e.toString()))),
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
    // Use providers to watch data instead of FutureBuilder
    final effectiveCountAsync = ref.watch(effectiveCountAtTransactionProvider(
      (productId: transaction.productId, timestamp: transaction.timestamp)
    ));
    final categorizedAnswersAsync = ref.watch(categorizedAnswersProvider(transaction.id));
    
    return effectiveCountAsync.when(
      data: (effectiveCount) {
        return categorizedAnswersAsync.when(
          data: (categorizedAnswers) {
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
                  Text(DateTimeUtils.formatDateTime(context, transaction.timestamp.toLocal())),
                  // Show per-scan attributes
                  if (perScanAnswers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _AnswerLabelsWidget(
                      answers: perScanAnswers,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  // Show "once" attributes with small text for subsequent scans
                  if (onceAnswers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _AnswerLabelsWidget(
                      answers: onceAnswers,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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
          loading: () => ListTile(
            title: Text(transaction.productId),
            subtitle: Text(DateTimeUtils.formatDateTime(context, transaction.timestamp.toLocal())),
            trailing: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, stackTrace) => ListTile(
            title: Text(transaction.productId),
            subtitle: Text(DateTimeUtils.formatDateTime(context, transaction.timestamp.toLocal())),
            trailing: const Icon(Icons.error, color: Colors.red),
          ),
        );
      },
      loading: () => ListTile(
        title: Text(transaction.productId),
        subtitle: Text(DateTimeUtils.formatDateTime(context, transaction.timestamp.toLocal())),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => ListTile(
        title: Text(transaction.productId),
        subtitle: Text(DateTimeUtils.formatDateTime(context, transaction.timestamp.toLocal())),
        trailing: const Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}

// Helper widget for displaying answer labels
class _AnswerLabelsWidget extends ConsumerWidget {
  final Map<String, String> answers;
  final TextStyle style;

  const _AnswerLabelsWidget({
    required this.answers,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(promptQuestionsProvider);
    
    return questionsAsync.when(
      data: (questions) {
        final labels = answers.entries.map((entry) {
          final question = questions.firstWhere(
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
          return '${question.label}: ${entry.value}';
        }).toList();
        
        return Text(labels.join(', '), style: style);
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.totalCountSetTo(newTotal, '${difference > 0 ? '+' : ''}$difference')),
          backgroundColor: difference > 0 ? Colors.green : Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(l10n.loading),
          ],
        ),
      );
    }

    final isPositive = _currentEffectiveCount > 0;
    final isNegative = _currentEffectiveCount < 0;

    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.transactionDetails),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            _InfoRow(label: l10n.product, value: widget.transaction.productId),
            _InfoRow(
              label: l10n.timestamp,
              value: DateTimeUtils.formatFullDateTime(context, widget.transaction.timestamp.toLocal()),
            ),
            _InfoRow(label: l10n.thisTransaction, value: '${widget.transaction.quantity > 0 ? '+' : ''}${widget.transaction.quantity}'),
            
            // Current effective count
            _InfoRow(
              label: l10n.currentTotal,
              value: _currentEffectiveCount.toString(),
              valueColor: isPositive
                  ? Colors.green
                  : isNegative
                      ? Colors.red
                      : Colors.grey,
            ),
            
            const SizedBox(height: 20),
            
            // Set new total section
            Text(l10n.setNewTotalCount, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: l10n.totalCount,
                      hintText: l10n.enterDesiredTotal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _setNewTotal,
                  child: Text(l10n.set),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Attributes
            if (_answers.isNotEmpty) ...[
              Text('${l10n.attributes}:', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: Text(l10n.close),
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

