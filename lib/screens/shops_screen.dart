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

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<void> _refresh() async {
    final f = _fetch();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  /// Only admin can add a new shop
  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ShopFormScreen()),
    );
    if (saved == true) _reload();
  }

  /// Tapping a shop opens its details + orders page
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
      backgroundColor: const Color(0xFFf1f5f9),

      // ── AppBar ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Shops',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Color(0xFF0f172a),
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFe2e8f0)),
        ),
      ),

      // ── FAB ──
      floatingActionButton: user.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: const Color(0xFF2563eb),
              icon: const Icon(
                Icons.add_business_outlined,
                color: Colors.white,
              ),
              label: const Text(
                'Add shop',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,

      body: Column(
        children: [
          // ── Search + Filter ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _reload(),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1e293b),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search shop name',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94a3b8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94a3b8),
                        size: 20,
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF94a3b8),
                                size: 18,
                              ),
                              onPressed: () {
                                _search.clear();
                                _reload();
                              },
                            ),
                      filled: true,
                      fillColor: const Color(0xFFf8fafc),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFe2e8f0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF3b82f6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String?>(
                  tooltip: 'District',
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: _district == null
                        ? const Color(0xFF64748b)
                        : const Color(0xFF2563eb),
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

          // ── District chip ──
          if (_district != null)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(
                    _district!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563eb),
                    ),
                  ),
                  backgroundColor: const Color(0xFFeff6ff),
                  side: const BorderSide(color: Color(0xFFbfdbfe), width: 1.5),
                  deleteIconColor: const Color(0xFF2563eb),
                  onDeleted: () {
                    _district = null;
                    _reload();
                  },
                ),
              ),
            ),

          Container(height: 1, color: const Color(0xFFe2e8f0)),

          // ── List ──
          Expanded(
            child: AsyncBody<List<Shop>>(
              future: _future,
              onRetry: _reload,
              builder: (context, shops) {
                return RefreshIndicator(
                  color: const Color(0xFF2563eb),
                  onRefresh: _refresh,
                  child: shops.isEmpty
                      ? const EmptyView(
                          icon: Icons.storefront_outlined,
                          message: 'No shops found',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
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

// ── Shop Card ────────────────────────────────────────────────────────────────

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
    const grey = TextStyle(color: Color(0xFF64748b), fontSize: 13);

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFeff6ff),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.storefront,
                color: Color(0xFF2563eb),
                size: 22,
              ),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF0f172a),
                          ),
                        ),
                      ),
                      if (!shop.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfff0f0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFf9b8b8),
                              width: 1.2,
                            ),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              color: Color(0xFFdc2626),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
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
            const Icon(Icons.chevron_right, color: Color(0xFF94a3b8)),
          ],
        ),
      ),
    );
  }
}
