import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/network_image.dart';
import '../widgets/state_views.dart';
import '../widgets/stock_chip.dart';
import 'order_flow.dart' show BrandSubmitBar;

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

  final TextEditingController _searchCtrl = TextEditingController();

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

  void _reload() {
    setState(() {
      _future = Repository.instance.brand(widget.brandId);
    });
  }

  List<Product> _filter(List<Product> all) {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) return all;

    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Order എടുക്കാൻ കഴിയുന്നത് salesman-ന് മാത്രം
    final canOrder = context.watch<AuthProvider>().user?.isSalesman ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brandName, overflow: TextOverflow.ellipsis),
      ),
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
                  onChanged: (v) {
                    setState(() => _query = v);
                  },
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
                        itemBuilder: (_, i) => ProductTile(
                          key: ValueKey(products[i].id),
                          product: products[i],
                          canOrder: canOrder,
                        ),
                      ),
              ),
            ],
          );
        },
      ),

      // ---------- ഈ brand-ന്റെ Submit (salesman മാത്രം) ----------
      bottomNavigationBar: canOrder
          ? BrandSubmitBar(brandId: widget.brandId, brandName: widget.brandName)
          : null,
    );
  }
}

// --------------------------------------------------
// PRODUCT TILE
// --------------------------------------------------

class ProductTile extends StatefulWidget {
  final Product product;

  /// false ആണെങ്കിൽ quantity എടുക്കാനുള്ള controls കാണിക്കില്ല (shop/admin)
  final bool canOrder;

  const ProductTile({super.key, required this.product, this.canOrder = true});

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  String _unit = 'piece';

  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // CartProvider ലഭ്യമായ ശേഷം ആദ്യ quantity load ചെയ്യുക.
    if (_ctrl.text.isEmpty) {
      _ctrl.text = _textFor(_unit);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _textFor(String unit) {
    final q = context.read<CartProvider>().qty(widget.product, unit);

    return q == 0 ? '' : '$q';
  }

  void _set(int quantity) {
    final max = widget.product.maxQtyFor(_unit);
    var q = quantity < 0 ? 0 : quantity;

    // Stock-ൽ കൂടുതൽ അടിക്കാൻ അനുവദിക്കില്ല
    if (q > max) {
      q = max;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            max == 0
                ? 'Stock ഇല്ല'
                : 'Stock-ൽ ആകെ $max ${_unit == 'bag' ? 'bag' : 'pcs'} മാത്രം',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    context.read<CartProvider>().setQty(widget.product, _unit, q);

    final text = q == 0 ? '' : '$q';

    if (_ctrl.text != text) {
      _ctrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartProvider>();

    final q = cart.qty(p, _unit);
    final rate = p.rateFor(_unit);
    final maxQty = p.maxQtyFor(_unit);
    final outOfStock = maxQty <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product details and stock
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: NetImage(url: p.image, size: 72),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.description,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'MRP: ${p.mrp > 0 ? formatMoney(p.mrp) : '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('Piece: ${formatMoney(p.price)}'),
                      Text(
                        'Bag (${p.piecesPerBag} pcs): '
                        '${formatMoney(p.bagPrice)}',
                      ),
                      const SizedBox(height: 6),
                      StockChip(product: p),
                    ],
                  ),
                ),
              ],
            ),

            // Existing scheme chips
            if (p.schemes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in p.schemes)
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

            // Quantity എടുക്കുന്ന ഭാഗം – salesman-ന് മാത്രം
            if (widget.canOrder) ...[
              const Divider(height: 20),

              // Piece / Bag selection
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'piece', label: Text('Piece')),
                  ButtonSegment(value: 'bag', label: Text('Bag')),
                ],
                selected: {_unit},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  final nextUnit = selection.first;

                  setState(() {
                    _unit = nextUnit;
                    _ctrl.value = TextEditingValue(
                      text: _textFor(nextUnit),
                      selection: TextSelection.collapsed(
                        offset: _textFor(nextUnit).length,
                      ),
                    );
                  });
                },
              ),

              const SizedBox(height: 10),

              // Quantity controls and price
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Decrease quantity',
                    icon: const Icon(Icons.remove),
                    onPressed: q == 0 ? null : () => _set(q - 1),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _ctrl,
                      enabled: !outOfStock,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: outOfStock ? '—' : '0',
                        isDense: true,
                        suffixText: _unit == 'bag' ? 'bag' : 'pcs',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _set(int.tryParse(value) ?? 0);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Increase quantity',
                    icon: const Icon(Icons.add),
                    onPressed: (outOfStock || q >= maxQty)
                        ? null
                        : () => _set(q + 1),
                  ),
                  const Spacer(),
                  if (q > 0)
                    Flexible(
                      child: Text(
                        formatMoney(rate * q),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
