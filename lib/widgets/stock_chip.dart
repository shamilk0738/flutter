import 'package:flutter/material.dart';

import '../models/product.dart';

class StockChip extends StatelessWidget {
  final Product product;
  const StockChip({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final out = product.stock <= 0;
    final color = out ? Colors.red : Colors.green.shade700;

    final parts = <String>[];
    if (product.stockBags > 0) parts.add('${product.stockBags} bag');
    if (product.stockPieces > 0) parts.add('${product.stockPieces} pcs');
    final text = out ? 'Out of stock' : 'Stock: ${parts.join(' + ')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
