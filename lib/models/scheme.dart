import '../utils/format.dart';

class Scheme {
  final int id;
  final String unit; // bag / piece
  final int minQuantity;
  final int freeQuantity;
  final double discountPercent;
  final String description;
  final String? startDate;
  final String? endDate;

  Scheme({
    required this.id,
    required this.unit,
    required this.minQuantity,
    required this.freeQuantity,
    required this.discountPercent,
    required this.description,
    this.startDate,
    this.endDate,
  });

  factory Scheme.fromJson(Map<String, dynamic> j) => Scheme(
        id: toInt(j['id']),
        unit: (j['unit'] ?? '').toString(),
        minQuantity: toInt(j['min_quantity']),
        freeQuantity: toInt(j['free_quantity']),
        discountPercent: toDouble(j['discount_percent']),
        description: (j['description'] ?? '').toString(),
        startDate: j['start_date']?.toString(),
        endDate: j['end_date']?.toString(),
      );

  /// Chip-ൽ കാണിക്കാനുള്ള ചെറിയ വിവരണം
  String get label {
    if (description.trim().isNotEmpty) return description;
    final parts = <String>[];
    if (freeQuantity > 0) parts.add('$freeQuantity free');
    if (discountPercent > 0) {
      parts.add('${discountPercent.toStringAsFixed(0)}% off');
    }
    return '$minQuantity $unit → ${parts.join(' + ')}';
  }
}
