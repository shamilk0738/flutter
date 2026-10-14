// ============================================================
//  lib/screens/order_flow.dart  – order എടുക്കാനുള്ള ചെറിയ widgets
//
//   1. ShopSearchField – Brands page-ന്റെ മുകളിൽ shop search
//   2. BrandSubmitBar  – ഒരു brand-ന്റെ ഉള്ളിൽ "Submit"
//   3. FinalSubmitBar  – Brands page-ന്റെ താഴെ "Final submit"
//
//  (ProductTile → brand_detail_screen.dart,
//   StockChip   → widgets/stock_chip.dart,
//   CartProvider → providers/cart_provider.dart,
//   ബില്ല് → order_summary_screen.dart)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'order_summary_screen.dart';

// ------------------------------------------------------------
// 1. ShopSearchField
// ------------------------------------------------------------
class ShopOption {
  final int id;
  final String name;
  const ShopOption(this.id, this.name);
}

class ShopSearchField extends StatelessWidget {
  final List<ShopOption> shops;
  const ShopSearchField({super.key, required this.shops});

  Future<void> _select(BuildContext context, ShopOption s) async {
    final cart = context.read<CartProvider>();
    if (cart.shopId != null && cart.shopId != s.id && cart.itemCount > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Shop മാറ്റണോ?'),
          content: Text('${cart.shopName}-ന്റെ എടുത്ത items മായ്ക്കപ്പെടും.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('വേണ്ട'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('മാറ്റുക'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    cart.startShop(s.id, s.name);
    if (context.mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Autocomplete<ShopOption>(
        displayStringForOption: (s) => s.name,
        optionsBuilder: (v) {
          final q = v.text.trim().toLowerCase();
          if (q.isEmpty) return const Iterable<ShopOption>.empty();
          return shops.where((s) => s.name.toLowerCase().contains(q));
        },
        onSelected: (s) => _select(context, s),
        fieldViewBuilder: (context, ctrl, focus, onSubmit) {
          return TextField(
            controller: ctrl,
            focusNode: focus,
            decoration: InputDecoration(
              hintText: cart.shopId == null
                  ? 'Shop name search ചെയ്യുക'
                  : cart.shopName,
              prefixIcon: const Icon(Icons.store),
              border: const OutlineInputBorder(),
              suffixIcon: cart.shopId == null
                  ? null
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// 2. BrandSubmitBar
// ------------------------------------------------------------
class BrandSubmitBar extends StatelessWidget {
  final int brandId;
  final String brandName;
  const BrandSubmitBar({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final n = cart.brandCount(brandId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            context.read<CartProvider>().submitBrand(brandId);
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context); // തിരിച്ച് Brands page → അടുത്ത brand
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  n == 0
                      ? '$brandName – ഒന്നും എടുത്തില്ല'
                      : '$brandName submit ചെയ്തു ($n items)',
                ),
              ),
            );
          },
          child: Text(
            'Submit $brandName'
            '${n > 0 ? '  •  ₹${cart.brandTotal(brandId).toStringAsFixed(2)}' : ''}',
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// 3. FinalSubmitBar
// ------------------------------------------------------------
class FinalSubmitBar extends StatelessWidget {
  const FinalSubmitBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.itemCount == 0) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
          ),
          child: Text(
            'Final submit  •  ${cart.itemCount} items  •  '
            '₹${cart.total.toStringAsFixed(2)}',
          ),
        ),
      ),
    );
  }
}
