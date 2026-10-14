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
    final repo = context
        .read<Repository>(); // നിങ്ങളുടെ repository എടുക്കുന്ന രീതി
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

      // നിലവിലെ new_order_screen-ൽ createOrder വിളിക്കുന്ന അതേ രീതി
      final shopId = cart.shopId;

      if (shopId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a shop before placing the order.'),
          ),
        );
        return;
      }

      await repo.createOrder(
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
    final lines = cart.lines;

    return Scaffold(
      appBar: AppBar(title: Text(cart.shopName)),
      body: lines.isEmpty
          ? const Center(child: Text('ഒന്നും എടുത്തിട്ടില്ല'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final l in lines)
                  Card(
                    child: ListTile(
                      title: Text(
                        l.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${l.product.brandName}\n'
                        '${l.quantity} ${l.unit} × ₹${l.rate.toStringAsFixed(2)}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${l.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cart.removeLine(l),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: lines.isEmpty
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
                          'Total (${lines.length} items)',
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
