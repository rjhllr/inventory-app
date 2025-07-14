import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app/view_models/scanning_vm.dart';
import '../providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigateToExportInfo(BuildContext context) {
    context.pushNamed('export-info');
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory App'),
      ),
      body: ListView(
        children: [
          const _NavTile(
            label: 'Start Stock-taking',
            routeName: 'scan',
            icon: Icons.qr_code_scanner,
          ),
          if (transactions.hasValue && transactions.value!.isNotEmpty)
            const _NavTile(
              label: 'Reset Stocks / Data',
              routeName: 'reset-stocks',
              icon: Icons.delete_sweep,
            ),
          const _NavTile(
            label: 'Stock-taking Settings',
            routeName: 'settings',
            icon: Icons.settings,
          ),
          const _NavTile(
            label: 'Product Database',
            routeName: 'products',
            icon: Icons.storage,
          ),
          const _NavTile(
            label: 'Transaction History',
            routeName: 'results',
            icon: Icons.list_alt,
          ),
          if (transactions.hasValue && transactions.value!.isNotEmpty)
            _ExportTile(
              onTap: () => _navigateToExportInfo(context),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String label;
  final String routeName;
  final IconData icon;

  const _NavTile({
    required this.label,
    required this.routeName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.pushNamed(routeName),
    );
  }
}



class _ExportTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ExportTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.file_download),
      title: const Text('Export CSV'),
      subtitle: const Text('Export inventory data as ZIP file'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 