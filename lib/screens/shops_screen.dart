import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/shop.dart';
import '../providers/auth_provider.dart';
import '../services/repository.dart';
import '../widgets/state_views.dart';
import 'shop_detail_screen.dart';
import 'shop_form_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final _search = TextEditingController();
  String? _district;
  late Future<List<Shop>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Shop>> _fetch() =>
      Repository.instance.shops(q: _search.text, district: _district);

  void _reload() => setState(() => _future = _fetch());

  Future<void> _refresh() async {
    final f = _fetch();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  /// Admin-ന് പുതിയ shop ചേർക്കാൻ മാത്രം
  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ShopFormScreen()),
    );
    if (saved == true) _reload();
  }

  /// Shop click ചെയ്താൽ details + orders ലിസ്റ്റ് page
  Future<void> _openDetail(Shop shop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Shops')),
      floatingActionButton: user.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Add shop'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _reload(),
                    decoration: InputDecoration(
                      hintText: 'Search shop name',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                _reload();
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  tooltip: 'District',
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: _district == null
                        ? null
                        : Theme.of(context).colorScheme.primary,
                  ),
                  onSelected: (v) {
                    _district = v == '' ? null : v;
                    _reload();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: '',
                      child: Text('All districts'),
                    ),
                    for (final d in keralaDistricts)
                      PopupMenuItem(value: d, child: Text(d)),
                  ],
                ),
              ],
            ),
          ),
          if (_district != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(_district!),
                  onDeleted: () {
                    _district = null;
                    _reload();
                  },
                ),
              ),
            ),
          Expanded(
            child: AsyncBody<List<Shop>>(
              future: _future,
              onRetry: _reload,
              builder: (context, shops) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: shops.isEmpty
                      ? const EmptyView(
                          icon: Icons.storefront_outlined,
                          message: 'Shops ഒന്നും ഇല്ല',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                          itemCount: shops.length,
                          itemBuilder: (_, i) => _ShopCard(
                            shop: shops[i],
                            isAdmin: user.isAdmin,
                            onOpen: () => _openDetail(shops[i]),
                          ),
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

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final bool isAdmin;
  final VoidCallback onOpen;

  const _ShopCard({
    required this.shop,
    required this.isAdmin,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(color: Colors.grey.shade700, fontSize: 13);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen, // Card click → shop details + orders
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.storefront, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            shop.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!shop.isActive) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'Inactive',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${shop.ownerName} • ${shop.phone}', style: grey),
                    Text(
                      '${shop.address}, ${shop.district} ${shop.pincode}',
                      style: grey,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shop.gstNumber.isNotEmpty)
                      Text('GST: ${shop.gstNumber}', style: grey),
                    if (isAdmin && shop.salesmanName.isNotEmpty)
                      Text('Salesman: ${shop.salesmanName}', style: grey),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
