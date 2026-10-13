import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../models/product.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/network_image.dart';
import '../widgets/state_views.dart';
import '../widgets/stock_chip.dart';

class BrandDetailScreen extends StatefulWidget {
  final int brandId;
  final String brandName;
  const BrandDetailScreen({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  late Future<Brand> _future;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = Repository.instance.brand(widget.brandId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() =>
      setState(() => _future = Repository.instance.brand(widget.brandId));

  List<Product> _filter(List<Product> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

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
              message: 'ഈ brand-ൽ products ഇല്ല',
            );
          }

          final products = _filter(brand.products);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search products in ${brand.name}',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const EmptyView(
                        icon: Icons.search_off,
                        message: 'ഒരു product-ഉം കണ്ടെത്താനായില്ല',
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        itemBuilder: (_, i) =>
                            _ProductCard(product: products[i]),
                      ),
              ),
            ],
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
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (product.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            product.description,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'MRP: ${product.mrp > 0 ? formatMoney(product.mrp) : '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('Piece: ${formatMoney(product.price)}'),
                      Text(
                        'Bag: ${formatMoney(product.bagRate)}  (${product.piecesPerBag} pcs)',
                      ),
                      const SizedBox(height: 6),
                      StockChip(product: product),
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
                      avatar: Icon(
                        Icons.card_giftcard,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      label: Text(
                        s.label,
                        style: const TextStyle(fontSize: 12),
                      ),
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
