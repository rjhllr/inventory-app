import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/export_service.dart';
import '../l10n/app_localizations.dart';

class ExportInfoScreen extends ConsumerWidget {
  const ExportInfoScreen({super.key});

  Future<void> _handleExport(BuildContext context, ExportService exportService) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n.generatingExport),
            ],
          ),
        ),
      );

      // Perform export
      await exportService.exportToZip();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportCompletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportService = ref.watch(exportServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportInformation),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export button moved to top for recurring users
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleExport(context, exportService),
                icon: const Icon(Icons.file_download),
                label: Text(l10n.generateExport),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l10n.exportFormat,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.exportDescription,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _ExportItem(
              title: l10n.productsCsv,
              description: l10n.productsCsvDescription,
              items: [
                l10n.productId,
                l10n.createdAtTimestamp,
                l10n.updatedAtTimestamp,
                l10n.oncePerProductAnswers,
              ],
            ),
            const SizedBox(height: 16),
            _ExportItem(
              title: l10n.transactionsCsv,
              description: l10n.transactionsCsvDescription,
              items: [
                l10n.transactionId,
                l10n.productId,
                l10n.quantityScanned,
                l10n.timestamp,
                l10n.createdAtTimestamp,
                l10n.updatedAtTimestamp,
                l10n.allPromptAnswers,
              ],
            ),
            const SizedBox(height: 16),
            _ExportItem(
              title: l10n.imagesFolder,
              description: l10n.imagesFolderDescription,
              items: [
                l10n.photosFromPrompts,
                l10n.filesReferencedInCsv,
                l10n.originalFilenames,
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.fileNaming,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.exportFilenamePattern,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }
}

class _ExportItem extends StatelessWidget {
  final String title;
  final String description;
  final List<String> items;

  const _ExportItem({
    required this.title,
    required this.description,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
              ],
            ),
          )),
        ],
      ),
    );
  }
} 