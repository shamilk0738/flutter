import 'package:flutter/material.dart';

class NetImage extends StatelessWidget {
  final String? url;
  final double size;
  final IconData fallback;
  final BoxFit fit;

  const NetImage({
    super.key,
    required this.url,
    this.size = 56,
    this.fallback = Icons.inventory_2_outlined,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.blue.shade50,
      child: Icon(fallback, color: Colors.blue.shade300, size: size * 0.5),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (c, child, p) => p == null ? child : placeholder,
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const StatusChip({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
