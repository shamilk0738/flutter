import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Wholesale',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4BEE)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FC),

      // Bottom Navigation
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE6E2FF),
        selectedIndex: 0,
        onDestinationSelected: (index) {
          final pages = ['Home', 'Orders', 'Products', 'Profile'];
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${pages[index]} selected')));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colorful Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5145CD),
                      Color(0xFF8267F5),
                      Color(0xFFB47CFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMART WHOLESALE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Business Management System',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CircleAvatar(
                          radius: 23,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF5B4BEE),
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Hello, Shamil 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Welcome back! Manage your business easily.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 22),

                    // Search Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Color(0xFF6C63FF)),
                          hintText: 'Search orders, products...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dashboard Title
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'Business Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25243A),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.calendar_month, color: Color(0xFF7568EA)),
                    SizedBox(width: 5),
                    Text('Today', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),

              // Dashboard Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 1.35,
                  children: const [
                    DashboardCard(
                      title: 'Total Orders',
                      value: '24',
                      subtitle: 'Today',
                      icon: Icons.shopping_cart_rounded,
                      color: Color(0xFFFF963D),
                      lightColor: Color(0xFFFFF0E1),
                    ),
                    DashboardCard(
                      title: 'Products',
                      value: '128',
                      subtitle: 'In inventory',
                      icon: Icons.inventory_2_rounded,
                      color: Color(0xFF4C83F5),
                      lightColor: Color(0xFFE7EEFF),
                    ),
                    DashboardCard(
                      title: 'Shopkeepers',
                      value: '56',
                      subtitle: 'Registered',
                      icon: Icons.store_rounded,
                      color: Color(0xFF18B887),
                      lightColor: Color(0xFFDDF8ED),
                    ),
                    DashboardCard(
                      title: 'Attendance',
                      value: '18/20',
                      subtitle: 'Staff present',
                      icon: Icons.people_alt_rounded,
                      color: Color(0xFF9A62E8),
                      lightColor: Color(0xFFF0E4FF),
                    ),
                  ],
                ),
              ),

              // Quick Actions
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 15),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25243A),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: QuickAction(
                        title: 'New Order',
                        icon: Icons.add_shopping_cart,
                        color: const Color(0xFF5B4BEE),
                        onTap: () => showMessage(context, 'New Order clicked'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickAction(
                        title: 'Products',
                        icon: Icons.inventory,
                        color: const Color(0xFF168FE5),
                        onTap: () => showMessage(context, 'Products clicked'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickAction(
                        title: 'Shops',
                        icon: Icons.store,
                        color: const Color(0xFF10A979),
                        onTap: () =>
                            showMessage(context, 'Shopkeepers clicked'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickAction(
                        title: 'Attendance',
                        icon: Icons.fact_check,
                        color: const Color(0xFFEF8B32),
                        onTap: () => showMessage(context, 'Attendance clicked'),
                      ),
                    ),
                  ],
                ),
              ),

              // Recent Orders
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25243A),
                      ),
                    ),
                    Spacer(),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF6654E8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const OrderTile(
                shop: 'Green Mart',
                detail: 'Order #1001 • 10:30 AM',
                amount: '₹2,450',
                status: 'Pending',
                color: Color(0xFFFFA726),
                icon: Icons.shopping_basket,
              ),

              const OrderTile(
                shop: 'City Stores',
                detail: 'Order #1002 • 11:15 AM',
                amount: '₹5,200',
                status: 'Completed',
                color: Color(0xFF16A779),
                icon: Icons.storefront,
              ),

              const OrderTile(
                shop: 'Fresh Basket',
                detail: 'Order #1003 • 12:00 PM',
                amount: '₹1,850',
                status: 'Pending',
                color: Color(0xFFFFA726),
                icon: Icons.local_grocery_store,
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Card Widget
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color lightColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF29283B),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555469),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Quick Action Widget
class QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424157),
            ),
          ),
        ],
      ),
    );
  }
}

// Recent Order Widget
class OrderTile extends StatelessWidget {
  final String shop;
  final String detail;
  final String amount;
  final String status;
  final Color color;
  final IconData icon;

  const OrderTile({
    super.key,
    required this.shop,
    required this.detail,
    required this.amount,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF29283B),
            ),
          ),
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
