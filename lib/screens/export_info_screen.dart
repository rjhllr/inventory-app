import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/export_service.dart';

class ExportInfoScreen extends ConsumerWidget {
  const ExportInfoScreen({super.key});

  Future<void> _handleExport(BuildContext context, ExportService exportService) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating export...'),
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
          const SnackBar(
            content: Text('Export completed successfully!'),
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
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportService = ref.watch(exportServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Information'),
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
                label: const Text('Generate Export'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The export will generate a ZIP file containing:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const _ExportItem(
              title: 'products.csv',
              description: 'Contains all product information including:',
              items: [
                'Product ID',
                'Created At timestamp',
                'Updated At timestamp',
                'All "once per product" prompt question answers',
              ],
            ),
            const SizedBox(height: 16),
            const _ExportItem(
              title: 'transactions.csv',
              description: 'Contains all transaction/scan records including:',
              items: [
                'Transaction ID',
                'Product ID',
                'Quantity scanned',
                'Timestamp',
                'Created At timestamp',
                'Updated At timestamp',
                'All prompt question answers (for each scan)',
              ],
            ),
            const SizedBox(height: 16),
            const _ExportItem(
              title: 'images/ folder',
              description: 'Contains all photos captured during scanning:',
              items: [
                'Photos from photo-type prompt questions',
                'Files referenced in CSV as "images/filename.jpg"',
                'Original file names preserved',
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'File Naming',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Export files are named: inventory_export_YYYYMMDD_HHMMSS.zip',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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