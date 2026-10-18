// ============================================================
//  lib/screens/order_flow.dart - small widgets for taking orders
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../utils/top_toast.dart';
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
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Change shop?'),
          content: Text('Items taken for ${cart.shopName} will be cleared.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Change'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    cart.startShop(s.id, s.name);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // Edit mode: shop cannot be changed
    if (cart.isEditing) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Editing order #${cart.editingOrderId}',
            prefixIcon: const Icon(Icons.store),
            suffixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
          ),
          child: Text(cart.shopName),
        ),
      );
    }

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
                  ? 'Search shop name'
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

            // Close the keyboard
            FocusManager.instance.primaryFocus?.unfocus();

            // Show the message at the top (root overlay, stays after pop)
            TopToast.show(
              context,
              n == 0
                  ? '$brandName - nothing selected'
                  : '$brandName submitted ($n items)',
              error: n == 0,
            );

            // Back to the Brands page for the next brand
            Navigator.pop(context);
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

    // Edit mode: button is always visible and returns to the Edit order page
    if (cart.isEditing) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Done  •  ${cart.itemCount} items  •  '
              '₹${cart.total.toStringAsFixed(2)}',
            ),
          ),
        ),
      );
    }

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
