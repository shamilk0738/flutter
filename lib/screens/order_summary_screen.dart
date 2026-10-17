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
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: const BackButton(color: Color(0xFF0f172a)),
        title: Text(
          'Bill – ${cart.shopName}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0f172a),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFe2e8f0)),
        ),
      ),

      body: groups.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 56,
                    color: Color(0xFFcbd5e1),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ഒന്നും എടുത്തിട്ടില്ല',
                    style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                // ── Bill Header Card ──
                _buildHeaderCard(cart),

                const SizedBox(height: 12),

                // ── Items Table Card ──
                _buildItemsCard(cart, groups),

                const SizedBox(height: 12),

                // ── Notes ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFe2e8f0),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1e293b),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Notes (optional)',
                      hintStyle: TextStyle(color: Color(0xFF94a3b8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

      // ── Bottom Place Order ──
      bottomNavigationBar: groups.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFe2e8f0), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${groups.length} brands · ${cart.itemCount} items',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748b),
                          ),
                        ),
                        Text(
                          '₹${cart.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0f172a),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563eb),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _place,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Place Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Header Card ─────────────────────────────────────────────────────────────
  Widget _buildHeaderCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFeff6ff),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.store_outlined,
              color: Color(0xFF2563eb),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BILL TO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94a3b8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cart.shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0f172a),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFeff6ff),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFbfdbfe), width: 1.5),
            ),
            child: Text(
              '${cart.itemCount} items',
              style: const TextStyle(
                color: Color(0xFF2563eb),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Items Table Card ─────────────────────────────────────────────────────────
  Widget _buildItemsCard(
    CartProvider cart,
    Map<dynamic, List<dynamic>> groups,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Table Column Header
          Container(
            color: const Color(0xFFf1f5f9),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: const Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    style: _thStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(flex: 4, child: Text('ITEM', style: _thStyle)),
                SizedBox(
                  width: 70,
                  child: Text(
                    'QTY',
                    style: _thStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'RATE',
                    style: _thStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'AMOUNT',
                    style: _thStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFe2e8f0)),

          // Brand groups
          for (final entry in groups.entries) ...[
            // Brand row
            Container(
              color: const Color(0xFFf0f7ff),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF2563eb),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.value.first.product.brandName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563eb),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Text(
                    '₹${cart.brandTotal(entry.key).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563eb),
                    ),
                  ),
                ],
              ),
            ),

            // Item rows
            for (int i = 0; i < entry.value.length; i++) ...[
              _ItemRow(
                index: i + 1,
                line: entry.value[i],
                isEven: i.isEven,
                onDelete: () => cart.removeLine(entry.value[i]),
              ),
              if (i < entry.value.length - 1)
                const Divider(
                  height: 1,
                  color: Color(0xFFf1f5f9),
                  indent: 12,
                  endIndent: 12,
                ),
            ],

            const Divider(height: 1, color: Color(0xFFe2e8f0)),
          ],

          // Total row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0f172a),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563eb),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table Header Style ────────────────────────────────────────────────────────
const _thStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF64748b),
  letterSpacing: 0.5,
);

// ── Item Row ─────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final int index;
  final dynamic line;
  final bool isEven;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.index,
    required this.line,
    required this.isEven,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.white : const Color(0xFFfafbfc),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Serial No
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFcbd5e1),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Item Name
          Expanded(
            flex: 4,
            child: Text(
              line.product.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0f172a),
              ),
            ),
          ),

          // Qty + Unit
          SizedBox(
            width: 70,
            child: Text(
              '${line.quantity} ${line.unit}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ),

          // Rate — right aligned, separate column
          SizedBox(
            width: 70,
            child: Text(
              '₹${line.rate.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
            ),
          ),

          // Amount — bold, blue
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    '₹${line.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0f172a),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close,
                    size: 15,
                    color: Color(0xFFcbd5e1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
