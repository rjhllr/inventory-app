import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app/view_models/scanning_vm.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigateToExportInfo(BuildContext context) {
    context.pushNamed('export-info');
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
      ),
      body: ListView(
        children: [
          _NavTile(
            label: l10n.startStockTaking,
            routeName: 'scan',
            icon: Icons.qr_code_scanner,
          ),
          if (transactions.hasValue && transactions.value!.isNotEmpty)
            _NavTile(
              label: l10n.resetStocksData,
              routeName: 'reset-stocks',
              icon: Icons.delete_sweep,
            ),
          _NavTile(
            label: l10n.stockTakingSettings,
            routeName: 'settings',
            icon: Icons.settings,
          ),
          _NavTile(
            label: l10n.productDatabase,
            routeName: 'products',
            icon: Icons.storage,
          ),
          _NavTile(
            label: l10n.transactionHistory,
            routeName: 'results',
            icon: Icons.list_alt,
          ),
          if (transactions.hasValue && transactions.value!.isNotEmpty)
            _ExportTile(
              onTap: () => _navigateToExportInfo(context),
              l10n: l10n,
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
  final AppLocalizations l10n;

  const _ExportTile({required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.file_download),
      title: Text(l10n.exportCSV),
      subtitle: Text(l10n.exportInventoryData),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 