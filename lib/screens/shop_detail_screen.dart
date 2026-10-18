import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/order.dart';
import '../models/shop.dart';
import '../providers/auth_provider.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/network_image.dart';
import '../widgets/state_views.dart';
import 'order_detail_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Order>> _fetch() =>
      Repository.instance.orders(shop: widget.shop.id);

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

  Future<void> _openOrder(Order o) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final shop = widget.shop;

    return Scaffold(
      appBar: AppBar(title: Text(shop.name, overflow: TextOverflow.ellipsis)),
      body: AsyncBody<List<Order>>(
        future: _future,
        onRetry: _reload,
        builder: (context, orders) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                // ---------- Shop details ----------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(
                                Icons.storefront,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!shop.isActive)
                              const Text(
                                'Inactive',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _infoRow(Icons.person_outline, 'Owner', shop.ownerName),
                        _infoRow(Icons.phone_outlined, 'Phone', shop.phone),
                        _infoRow(
                          Icons.location_on_outlined,
                          'Address',
                          '${shop.address}, ${shop.district} ${shop.pincode}',
                        ),
                        _infoRow(Icons.receipt_outlined, 'GST', shop.gstNumber),
                        if (user.isAdmin)
                          _infoRow(
                            Icons.badge_outlined,
                            'Salesman',
                            shop.salesmanName,
                          ),
                      ],
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total orders',
                        '${orders.length}',
                        Icons.receipt_long,
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
                  child: Text(
                    'Orders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),

                if (orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'ഈ shop-ന് orders ഒന്നും ഇല്ല',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                for (final o in orders)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openOrder(o),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDateTime(o.createdAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order #${o.id}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatMoney(o.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusChip(
                                  status: o.status,
                                  color: statusColor(o.status),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
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
}
