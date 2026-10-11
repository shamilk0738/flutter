import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'brands_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'shops_screen.dart';

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  const _TabItem(this.label, this.icon, this.selectedIcon, this.page);
}

/// Role അനുസരിച്ച് bottom navigation tabs മാറും
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  List<_TabItem> _tabsFor(String role) {
    const brands = _TabItem(
      'Brands',
      Icons.category_outlined,
      Icons.category,
      BrandsScreen(),
    );
    const shops = _TabItem(
      'Shops',
      Icons.storefront_outlined,
      Icons.storefront,
      ShopsScreen(),
    );
    const orders = _TabItem(
      'Orders',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      OrdersScreen(),
    );
    const report = _TabItem(
      'Report',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
      ReportScreen(),
    );
    const profile = _TabItem(
      'Profile',
      Icons.person_outline,
      Icons.person,
      ProfileScreen(),
    );

    switch (role) {
      case 'admin':
        return const [orders, shops, brands, report, profile];
      case 'salesman':
        return const [brands, shops, orders, profile];
      default: // shop
        return const [brands, orders, profile];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final tabs = _tabsFor(user.role);
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: tabs[index].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
