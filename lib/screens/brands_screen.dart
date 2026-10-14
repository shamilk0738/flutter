import 'package:flutter/material.dart';

import '../config/constants.dart';
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

  // Search variables
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = Repository.instance.brands();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchCtrl.text.trim().toLowerCase();
    });
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
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.store),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                kDistributorName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search brands...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchCtrl.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<Brand>>(
              future: _future,
              onRetry: _reload,
              builder: (context, brands) {
                final filteredBrands = brands.where((brand) {
                  return brand.name.toLowerCase().contains(_query);
                }).toList();

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: filteredBrands.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 100),
                            EmptyView(
                              icon: Icons.category_outlined,
                              message: _query.isEmpty
                                  ? 'Brands ഒന്നും ഇല്ല'
                                  : 'Matching brands ഒന്നും ഇല്ല',
                            ),
                          ],
                        )
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
                          itemCount: filteredBrands.length,
                          itemBuilder: (_, i) =>
                              _BrandCard(brand: filteredBrands[i]),
                        ),
                );
              },
            ),
          ),
        ],
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
            builder: (_) =>
                BrandDetailScreen(brandId: brand.id, brandName: brand.name),
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
                  Text(
                    brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${brand.productCount} products',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
