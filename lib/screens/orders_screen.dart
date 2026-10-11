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
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _status; // null = എല്ലാം
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Order>> _fetch() => Repository.instance.orders(status: _status);

  void _reload() => setState(() => _future = _fetch());

  Future<void> _refresh() async {
    final f = _fetch();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _newOrder() async {
    final order = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewOrderScreen()),
    );
    if (order != null && mounted) {
      _reload();
      showSnack(context,
          'Order #${order.id} സ്വീകരിച്ചു • ${formatMoney(order.totalAmount)}');
    }
  }

  Future<void> _openOrder(Order o) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
    );
    if (mounted) _reload(); // status മാറിയിരിക്കാം
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(title: Text(user.isShop ? 'My orders' : 'Orders')),
      floatingActionButton: user.isSalesman
          ? FloatingActionButton.extended(
              onPressed: _newOrder,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('New order'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _filterChip('All', null),
                for (final s in orderStatuses) _filterChip(capitalize(s), s),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<List<Order>>(
              future: _future,
              onRetry: _reload,
              builder: (context, orders) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: orders.isEmpty
                      ? const EmptyView(
                          icon: Icons.receipt_long_outlined,
                          message: 'Orders ഒന്നും ഇല്ല')
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                          itemCount: orders.length,
                          itemBuilder: (_, i) => _OrderCard(
                            order: orders[i],
                            showSalesman: !user.isSalesman,
                            onTap: () => _openOrder(orders[i]),
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

  Widget _filterChip(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _status == value,
        onSelected: (_) {
          _status = value;
          _reload();
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool showSalesman;
  final VoidCallback onTap;
  const _OrderCard(
      {required this.order, required this.showSalesman, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('#${order.id}  ${order.shopName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  StatusChip(
                      status: order.status, color: statusColor(order.status)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(formatMoney(order.totalAmount),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(formatDateTime(order.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              if (showSalesman && order.salesmanName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('By ${order.salesmanName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
