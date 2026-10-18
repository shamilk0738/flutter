import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';
import 'new_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _future;
  Order? _order;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Order> _fetch() async {
    final o = await Repository.instance.order(widget.orderId);
    if (mounted) setState(() => _order = o);
    return o;
  }

  void _reload() => setState(() => _future = _fetch());

  Future<void> _edit(Order order) async {
    final updated = await Navigator.push<Order>(
      context,
      MaterialPageRoute(builder: (_) => NewOrderScreen(editOrder: order)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _order = updated;
      _future = Future.value(updated);
    });
    showSnack(context, 'Order #${updated.id} update ചെയ്തു');
  }

  Future<void> _changeStatus(Order order, String status) async {
    if (status == order.status) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change status?'),
        content: Text('Order #${order.id} → ${capitalize(status)} ആക്കണോ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _updating = true);
    try {
      final updated = await Repository.instance.updateOrderStatus(
        order.id,
        status,
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _future = Future.value(updated);
      });
      showSnack(context, 'Status ${capitalize(status)} ആക്കി');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'complete':
        return const Color(0xFF16a34a);
      case 'cancelled':
        return const Color(0xFFdc2626);
      default:
        return const Color(0xFFe07b00);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'complete':
        return const Color(0xFFe6f9f0);
      case 'cancelled':
        return const Color(0xFFfff0f0);
      default:
        return const Color(0xFFfff4e5);
    }
  }

  Color _statusBorder(String s) {
    switch (s) {
      case 'complete':
        return const Color(0xFFa3e6c5);
      case 'cancelled':
        return const Color(0xFFf9b8b8);
      default:
        return const Color(0xFFfcd9a0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final current = _order;
    final canEdit =
        current != null &&
        current.status == 'pending' &&
        (user.isAdmin || user.isSalesman);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: const BackButton(color: Color(0xFF0f172a)),
        title: Text(
          'Bill #${widget.orderId}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0f172a),
          ),
        ),
        actions: [
          if (canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563eb)),
                tooltip: 'Edit order',
                onPressed: () => _edit(current),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFe2e8f0)),
        ),
      ),

      body: AsyncBody<Order>(
        future: _future,
        onRetry: _reload,
        builder: (context, order) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
            children: [
              // ── Bill Header Card ──
              _buildHeaderCard(order),

              const SizedBox(height: 12),

              // ── Status Editor (admin only) ──
              if (user.isAdmin) ...[
                _buildStatusEditor(order),
                const SizedBox(height: 12),
              ],

              // ── Items Table Card ──
              _buildItemsCard(order),

              const SizedBox(height: 12),

              // ── Notes ──
              if (order.notes.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFe2e8f0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_outlined,
                        size: 16,
                        color: Color(0xFF94a3b8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.notes,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop + Status
          Row(
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
                      order.shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0f172a),
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(order.status),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusBorder(order.status),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  capitalize(order.status),
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFf1f5f9)),
          const SizedBox(height: 12),

          _infoRow(Icons.tag, 'Bill No', '#${order.id}'),
          if (order.salesmanName.isNotEmpty)
            _infoRow(Icons.person_outline, 'Salesman', order.salesmanName),
          _infoRow(
            Icons.schedule_outlined,
            'Placed',
            formatDateTime(order.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF94a3b8)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusEditor(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Update Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0f172a),
                ),
              ),
              if (_updating) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563eb),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in orderStatuses)
                GestureDetector(
                  onTap: _updating ? null : () => _changeStatus(order, s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: order.status == s
                          ? _statusBg(s)
                          : const Color(0xFFf1f5f9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: order.status == s
                            ? _statusBorder(s)
                            : const Color(0xFFe2e8f0),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      capitalize(s),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: order.status == s
                            ? _statusColor(s)
                            : const Color(0xFF64748b),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Table Header
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
                  width: 68,
                  child: Text(
                    'QTY',
                    style: _thStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 68,
                  child: Text(
                    'RATE',
                    style: _thStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 70,
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

          // Item rows
          for (int i = 0; i < order.items.length; i++) ...[
            _BillItemRow(index: i + 1, item: order.items[i], isEven: i.isEven),
            if (i < order.items.length - 1)
              const Divider(
                height: 1,
                color: Color(0xFFf1f5f9),
                indent: 12,
                endIndent: 12,
              ),
          ],

          const Divider(height: 1, color: Color(0xFFe2e8f0)),

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
                  formatMoney(order.totalAmount),
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

const _thStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF64748b),
  letterSpacing: 0.5,
);

class _BillItemRow extends StatelessWidget {
  final int index;
  final OrderItem item;
  final bool isEven;

  const _BillItemRow({
    required this.index,
    required this.item,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.white : const Color(0xFFfafbfc),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Serial no
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

          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0f172a),
                  ),
                ),
                if (item.freeQuantity > 0 || item.discountPercent > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (item.freeQuantity > 0)
                          _tag('+${item.freeQuantity} ${item.unit} free'),
                        if (item.discountPercent > 0)
                          _tag(
                            '${item.discountPercent.toStringAsFixed(0)}% off',
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Qty
          SizedBox(
            width: 68,
            child: Text(
              '${item.quantity} ${item.unit}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ),

          // Rate — separate column
          SizedBox(
            width: 68,
            child: Text(
              formatMoney(item.unitPrice),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
            ),
          ),

          SizedBox(
            width: 70,
            child: Text(
              formatMoney(item.lineTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0f172a),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFf0fdf4),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFbbf7d0)),
    ),
    child: Text(
      t,
      style: const TextStyle(
        color: Color(0xFF16a34a),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
