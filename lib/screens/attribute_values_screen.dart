import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/scanning_vm.dart';
import '../l10n/app_localizations.dart';

class AttributeValuesScreen extends ConsumerWidget {
  final String productId;
  final String questionId;

  const AttributeValuesScreen({Key? key, required this.productId, required this.questionId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Fetch attribute counts across product for both per-scan and once attributes
    final perScanCountsAsync = ref.watch(perScanAttributeCountsProvider(productId));
    final onceCountsAsync = ref.watch(onceAttributeCountsProvider(productId));

    return FutureBuilder<String>(
      future: ref.read(scanningVmProvider).getQuestionLabel(questionId),
      builder: (context, labelSnapshot) {
        final label = labelSnapshot.data ?? questionId;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.valuesListTitle(label)),
          ),
          body: perScanCountsAsync.when(
            data: (perScanMap) {
              return onceCountsAsync.when(
                data: (onceMap) {
                  // Determine which map contains the requested questionId
                  Map<String, int> counts = {};
                  if (perScanMap.containsKey(questionId)) {
                    counts = perScanMap[questionId]!;
                  } else if (onceMap.containsKey(questionId)) {
                    counts = onceMap[questionId]!;
                  }

                  if (counts.isEmpty) {
                    return Center(child: Text(l10n.loading));
                  }

                  final entries = counts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        title: Text(entry.key),
                        trailing: Text('${entry.value}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(error.toString())),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text(error.toString())),
          ),
        );
      },
    );
  }
} 