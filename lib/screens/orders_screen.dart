import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';
import 'brands_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _status;
  late Future<List<Order>> _future;
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Order>> _fetch() async {
    final orders = await Repository.instance.orders(status: _status);
    _allOrders = orders;
    _applySearch(_searchQuery);
    return orders;
  }

  void _applySearch(String q) {
    setState(() {
      _searchQuery = q;
      if (q.isEmpty) {
        _filteredOrders = List.from(_allOrders);
      } else {
        _filteredOrders = _allOrders
            .where(
              (o) =>
                  o.shopName.toLowerCase().contains(q.toLowerCase()) ||
                  o.id.toString().contains(q) ||
                  o.salesmanName.toLowerCase().contains(q.toLowerCase()),
            )
            .toList();
      }
    });
  }

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

  Future<void> _newOrder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BrandsScreen()),
    );
    if (mounted) _reload();
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

    return Scaffold(
      backgroundColor: const Color(0xFFf1f5f9),

      // ── AppBar ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          user.isShop ? 'My Orders' : 'Orders',
          style: const TextStyle(
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
      floatingActionButton: user.isSalesman
          ? FloatingActionButton.extended(
              onPressed: _newOrder,
              backgroundColor: const Color(0xFF2563eb),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text(
                'New Order',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,

      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          return Column(
            children: [
              // ── Search Bar ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: _applySearch,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1e293b),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by shop, bill no...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF94a3b8),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF94a3b8),
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch('');
                            },
                          )
                        : null,
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

              // ── Filter Chips ──
              Container(
                color: Colors.white,
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  children: [
                    _filterChip('All', null),
                    for (final s in orderStatuses)
                      _filterChip(capitalize(s), s),
                  ],
                ),
              ),

              Container(height: 1, color: const Color(0xFFe2e8f0)),

              // ── Body ──
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563eb),
                        ),
                      )
                    : snapshot.hasError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFdc2626),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Something went wrong',
                              style: TextStyle(color: Color(0xFF64748b)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _reload,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF2563eb),
                        onRefresh: _refresh,
                        child: _filteredOrders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.4,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _searchQuery.isNotEmpty
                                              ? Icons.search_off
                                              : Icons.receipt_long_outlined,
                                          size: 56,
                                          color: const Color(0xFFcbd5e1),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? 'No orders match "$_searchQuery"'
                                              : 'Orders ഒന്നും ഇല്ല',
                                          style: const TextStyle(
                                            color: Color(0xFF94a3b8),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  100,
                                ),
                                itemCount: _filteredOrders.length,
                                itemBuilder: (_, i) => _OrderCard(
                                  order: _filteredOrders[i],
                                  showSalesman: !user.isSalesman,
                                  onTap: () => _openOrder(_filteredOrders[i]),
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

  Widget _filterChip(String label, String? value) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _status = value;
          _reload();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563eb) : const Color(0xFFf1f5f9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563eb)
                  : const Color(0xFFe2e8f0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF64748b),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool showSalesman;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.showSalesman,
    required this.onTap,
  });

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff6ff),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: const Color.fromRGBO(191, 219, 254, 1),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    '${order.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563eb),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Shop name
                Expanded(
                  child: Text(
                    order.shopName.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0f172a),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFf1f5f9)),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.currency_rupee,
                  size: 16,
                  color: Color(0xFF0f172a),
                ),
                Text(
                  formatMoney(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0f172a),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF94a3b8),
                ),
                const SizedBox(width: 4),
                Text(
                  formatDateTime(order.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            if (showSalesman && order.salesmanName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Color(0xFF94a3b8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'By ${order.salesmanName}',
                    style: const TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 13,
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
