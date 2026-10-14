import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/repository.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    final cart = context.read<CartProvider>();
    final shopId = cart.shopId;

    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop before placing the order.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = cart.lines
          .map(
            (l) => {
              'product': l.product.id,
              'unit': l.unit,
              'quantity': l.quantity,
            },
          )
          .toList();

      // order_detail_screen-ൽ ഉപയോഗിക്കുന്ന അതേ രീതി (Repository.instance)
      await Repository.instance.createOrder(
        shop: shopId,
        notes: _notesCtrl.text.trim(),
        items: payload,
      );

      if (!mounted) return;
      final shop = cart.shopName;
      cart.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$shop-ന്റെ order ചെയ്തു')));
      // Shop list screen-ലേക്ക് തിരിച്ച് → അടുത്ത shop
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final groups = cart.linesByBrand;

    return Scaffold(
      appBar: AppBar(title: Text('Bill – ${cart.shopName}')),
      body: groups.isEmpty
          ? const Center(child: Text('ഒന്നും എടുത്തിട്ടില്ല'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---------- Brand-wise ----------
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value.first.product.brandName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '₹${cart.brandTotal(entry.key).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  for (final l in entry.value)
                    Card(
                      child: ListTile(
                        title: Text(
                          l.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${l.quantity} ${l.unit} × ₹${l.rate.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${l.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => cart.removeLine(l),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: groups.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total (${groups.length} brands, ${cart.itemCount} items)',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '₹${cart.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: _saving ? null : _place,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Place order'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
