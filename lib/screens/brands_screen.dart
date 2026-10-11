import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../services/repository.dart';
import '../widgets/network_image.dart';
import '../widgets/state_views.dart';
import 'brand_detail_screen.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  late Future<List<Brand>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repository.instance.brands();
  }

  void _reload() => setState(() => _future = Repository.instance.brands());

  Future<void> _refresh() async {
    final f = Repository.instance.brands();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brands')),
      body: AsyncBody<List<Brand>>(
        future: _future,
        onRetry: _reload,
        builder: (context, brands) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: brands.isEmpty
                ? const EmptyView(
                    icon: Icons.category_outlined,
                    message: 'Brands ഒന്നും ഇല്ല')
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: brands.length,
                    itemBuilder: (_, i) => _BrandCard(brand: brands[i]),
                  ),
          );
        },
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final Brand brand;
  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrandDetailScreen(
                brandId: brand.id, brandName: brand.name),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (_, c) => NetImage(
                  url: brand.logo,
                  size: c.maxHeight,
                  fit: BoxFit.contain,
                  fallback: Icons.sell_outlined,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${brand.productCount} products',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
