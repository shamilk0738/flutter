import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart'; // പുതിയത്
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DistributorApp());
}

class DistributorApp extends StatelessWidget {
  const DistributorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // മാറ്റം
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()), // പുതിയത്
      ],
      child: MaterialApp(
        title: 'Distributor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1565C0),
          scaffoldBackgroundColor: const Color(0xFFF5F7FB),
          appBarTheme: const AppBarTheme(centerTitle: false),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Login ചെയ്തിട്ടുണ്ടോ എന്നനുസരിച്ച് Login / Home കാണിക്കുന്നു
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        // Logout / session expire ആകുമ്പോൾ തുറന്നിരിക്കുന്ന screens അടയ്ക്കുക
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context
                .read<CartProvider>()
                .clear(); // പുതിയത്: അടുത്ത user-ന് പഴയ cart കാണരുത്
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        });
        return const LoginScreen();
    }
  }
}
