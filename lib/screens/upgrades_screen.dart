import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.upgrades)),
      body: Center(
        child: Text(l10n.premiumFeaturesComingSoon),
      ),
    );
  }
} 