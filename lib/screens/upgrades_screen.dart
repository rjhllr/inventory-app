import 'package:flutter/material.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrades')),
      body: const Center(
        child: Text('Premium features coming soon'),
      ),
    );
  }
} 