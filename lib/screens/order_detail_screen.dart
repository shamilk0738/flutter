import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/network_image.dart';
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
  Order?
  _order; // AppBar-ലെ Edit button-ന് order വേണം, അതിനാൽ ഇവിടെ സൂക്ഷിക്കുന്നു
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final current = _order;
    final canEdit =
        current != null &&
        current.status == 'pending' &&
        (user.isAdmin || user.isSalesman);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit order',
              onPressed: () => _edit(current),
            ),
        ],
      ),
      body: AsyncBody<Order>(
        future: _future,
        onRetry: _reload,
        builder: (context, order) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _summary(order),
              if (user.isAdmin) _statusEditor(order),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              for (final item in order.items) _itemCard(item),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatMoney(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(Order o) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.shopName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip(status: o.status, color: statusColor(o.status)),
              ],
            ),
            const SizedBox(height: 8),
            _row(Icons.person_outline, 'Salesman', o.salesmanName),
            _row(Icons.schedule, 'Placed', formatDateTime(o.createdAt)),
            if (o.notes.trim().isNotEmpty) _row(Icons.notes, 'Notes', o.notes),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statusEditor(Order o) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Update status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (_updating) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final s in orderStatuses)
                  ChoiceChip(
                    label: Text(capitalize(s)),
                    selected: o.status == s,
                    onSelected: _updating ? null : (_) => _changeStatus(o, s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(OrderItem i) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    i.unit == 'bag'
                        ? '${i.quantity} bag × ${formatMoney(i.unitPrice)} / bag'
                        : '${i.quantity} pcs × ${formatMoney(i.unitPrice)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (i.freeQuantity > 0 || i.discountPercent > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (i.freeQuantity > 0)
                            _tag('+${i.freeQuantity} ${i.unit} free'),
                          if (i.discountPercent > 0)
                            _tag(
                              '${i.discountPercent.toStringAsFixed(0)}% off',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              formatMoney(i.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      t,
      style: TextStyle(color: Colors.green.shade800, fontSize: 12),
    ),
  );
}
