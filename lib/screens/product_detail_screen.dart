import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(productId)),
      body: Center(
        child: Text('Details for $productId will be shown here.\n(Scan history, attributes, etc.)'),
      ),
    );
  }
} 