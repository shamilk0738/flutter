import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

/// Order ലൈൻ: product + unit + quantity
class _Line {
  final Product product;
  final String unit;
  final int qty;
  _Line(this.product, this.unit, this.qty);
}

class _OrderData {
  final List<Shop> shops;
  final List<Product> products;
  _OrderData(this.shops, this.products);
}

/// Salesman-ന് order എടുക്കാൻ. വില, scheme, total എല്ലാം server കണക്കാക്കും.
/// Order വിജയിച്ചാൽ Navigator.pop(context, order) ചെയ്യും.
///
/// [editOrder] കൊടുത്താൽ Edit mode: നിലവിലെ items prefill ആകും, shop മാറ്റാൻ പറ്റില്ല,
/// Save ചെയ്യുമ്പോൾ update ആയ Order തിരികെ കൊടുക്കും.
class NewOrderScreen extends StatefulWidget {
  final Shop? initialShop;
  final Order? editOrder;
  const NewOrderScreen({super.key, this.initialShop, this.editOrder});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  late Future<_OrderData> _future;
  int? _shopId;
  final List<_Line> _lines = [];
  final _notes = TextEditingController();
  bool _submitting = false;

  bool _prefilled = false;
  int _skippedCount = 0; // ഇപ്പോൾ available അല്ലാത്ത products

  bool get _isEdit => widget.editOrder != null;

  @override
  void initState() {
    super.initState();
    _shopId = widget.editOrder?.shop ?? widget.initialShop?.id;
    _future = _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<_OrderData> _load() async {
    final res = await Future.wait([
      Repository.instance.shops(),
      Repository.instance.products(),
    ]);
    final shops = res[0] as List<Shop>;
    final products = res[1] as List<Product>;
    _prefillIfEditing(products);
    return _OrderData(shops, products);
  }

  /// Edit mode-ൽ നിലവിലെ order-ന്റെ items + notes form-ൽ നിറയ്ക്കുന്നു (ഒരു തവണ മാത്രം)
  void _prefillIfEditing(List<Product> products) {
    final o = widget.editOrder;
    if (o == null || _prefilled) return;
    _prefilled = true;
    _notes.text = o.notes;
    for (final item in o.items) {
      final match = products.where((p) => p.id == item.product);
      if (match.isEmpty) {
        _skippedCount++;
        continue;
      }
      _lines.add(_Line(match.first, item.unit, item.quantity));
    }
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addOrEdit(List<Product> products, {int? index}) async {
    final line = await showModalBottomSheet<_Line>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LineSheet(
        products: products,
        initial: index == null ? null : _lines[index],
      ),
    );
    if (line == null) return;
    setState(() {
      if (index == null) {
        _lines.add(line);
      } else {
        _lines[index] = line;
      }
    });
  }

  Future<void> _submit() async {
    if (_shopId == null) {
      showSnack(context, 'Shop തിരഞ്ഞെടുക്കുക', error: true);
      return;
    }
    if (_lines.isEmpty) {
      showSnack(context, 'കുറഞ്ഞത് ഒരു product ചേർക്കുക', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final items = [
        for (final l in _lines)
          {'product': l.product.id, 'unit': l.unit, 'quantity': l.qty},
      ];

      final Order order;
      if (_isEdit) {
        order = await Repository.instance.updateOrder(
          widget.editOrder!.id,
          notes: _notes.text.trim(),
          items: items,
        );
      } else {
        order = await Repository.instance.createOrder(
          shop: _shopId!,
          notes: _notes.text.trim(),
          items: items,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, order);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), error: true);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _lines.length;
    final itemsText = '$n item${n == 1 ? '' : 's'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit order #${widget.editOrder!.id}' : 'New order',
        ),
      ),
      body: AsyncBody<_OrderData>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          if (data.shops.isEmpty) {
            return const EmptyView(
              icon: Icons.storefront_outlined,
              message: 'നിങ്ങൾക്ക് shops assign ചെയ്തിട്ടില്ല',
            );
          }
          final shopValue = data.shops.any((s) => s.id == _shopId)
              ? _shopId
              : null;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DropdownButtonFormField<int>(
                      value: shopValue,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Shop',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      items: [
                        for (final s in data.shops)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      // Edit mode-ൽ shop മാറ്റാൻ പറ്റില്ല
                      onChanged: _isEdit
                          ? null
                          : (v) => setState(() => _shopId = v),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          onPressed: () => _addOrEdit(data.products),
                          icon: const Icon(Icons.add),
                          label: const Text('Add item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_skippedCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '$_skippedCount item(s) ഇപ്പോൾ available അല്ല. '
                          'Save ചെയ്താൽ അവ order-ൽ നിന്ന് ഒഴിവാക്കപ്പെടും.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_lines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Products ചേർക്കുക',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    for (var i = 0; i < _lines.length; i++)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            _lines[i].product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_lines[i].qty} ${_lines[i].unit}  •  ${_lines[i].product.brandName}',
                          ),
                          onTap: () => _addOrEdit(data.products, index: i),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => _lines.removeAt(i)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'eg: Deliver tomorrow',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEdit
                          ? 'Save ചെയ്യുമ്പോൾ വില, scheme, total എന്നിവ server വീണ്ടും കണക്കാക്കും.'
                          : 'വില, scheme, total എന്നിവ order ചെയ്ത ശേഷം server കണക്കാക്കും.',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? 'Save changes ($itemsText)'
                                  : 'Place order ($itemsText)',
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Product, unit, quantity തിരഞ്ഞെടുക്കാനുള്ള bottom sheet
class _LineSheet extends StatefulWidget {
  final List<Product> products;
  final _Line? initial;
  const _LineSheet({required this.products, this.initial});

  @override
  State<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends State<_LineSheet> {
  Product? _product;
  String _unit = 'bag';
  final _qty = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _product = widget.initial!.product;
      _unit = widget.initial!.unit;
      _qty.text = widget.initial!.qty.toString();
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  void _done() {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    if (_product == null) {
      setState(() => _error = 'Product തിരഞ്ഞെടുക്കുക');
      return;
    }
    if (qty <= 0) {
      setState(() => _error = 'Quantity 1 അല്ലെങ്കിൽ കൂടുതൽ വേണം');
      return;
    }
    Navigator.pop(context, _Line(_product!, _unit, qty));
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final schemes = p?.schemesFor(_unit) ?? [];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: p?.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Product'),
              items: [
                for (final x in widget.products)
                  DropdownMenuItem(
                    value: x.id,
                    child: Text(
                      '${x.brandName} • ${x.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => setState(() {
                _product = widget.products.firstWhere((x) => x.id == id);
                _error = null;
              }),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'bag', label: Text('Bag')),
                ButtonSegment(value: 'piece', label: Text('Piece')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            if (p != null) ...[
              const SizedBox(height: 10),
              Text(
                _unit == 'bag'
                    ? 'Rate: ${formatMoney(p.bagRate)} / bag  (${p.piecesPerBag} pcs)'
                    : 'Rate: ${formatMoney(p.price)} / piece',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (schemes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in schemes)
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
                ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Quantity ($_unit)',
                errorText: _error,
              ),
              onSubmitted: (_) => _done(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _done,
              child: Text(
                widget.initial == null ? 'Add to order' : 'Update item',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
