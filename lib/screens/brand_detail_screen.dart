import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../models/product.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/network_image.dart';
import '../widgets/state_views.dart';

class BrandDetailScreen extends StatefulWidget {
  final int brandId;
  final String brandName;
  const BrandDetailScreen(
      {super.key, required this.brandId, required this.brandName});

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  late Future<Brand> _future;

  @override
  void initState() {
    super.initState();
    _future = Repository.instance.brand(widget.brandId);
  }

  void _reload() =>
      setState(() => _future = Repository.instance.brand(widget.brandId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.brandName)),
      body: AsyncBody<Brand>(
        future: _future,
        onRetry: _reload,
        builder: (context, brand) {
          if (brand.products.isEmpty) {
            return const EmptyView(
                icon: Icons.inventory_2_outlined,
                message: 'ഈ brand-ൽ products ഇല്ല');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: brand.products.length,
            itemBuilder: (_, i) => _ProductCard(product: brand.products[i]),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: NetImage(url: product.image, size: 72),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (product.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(product.description,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      const SizedBox(height: 8),
                      Text('Piece: ${formatMoney(product.price)}'),
                      Text(
                          'Bag: ${formatMoney(product.bagRate)}  (${product.piecesPerBag} pcs)'),
                    ],
                  ),
                ),
              ],
            ),
            if (product.schemes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in product.schemes)
                    Chip(
                      avatar: Icon(Icons.card_giftcard,
                          size: 16, color: Colors.green.shade700),
                      label: Text(s.label,
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
