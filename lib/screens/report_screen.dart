import 'package:flutter/material.dart';

import '../models/salesman_report.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DateTimeRange _range;
  late Future<List<SalesmanReport>> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    _future = _fetch();
  }

  Future<List<SalesmanReport>> _fetch() => Repository.instance
      .salesmanPerformance(from: _range.start, to: _range.end);

  void _reload() => setState(() => _future = _fetch());

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 31)),
    );
    if (r != null) {
      _range = r;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salesman performance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(
                  '${formatDate(apiDate(_range.start))} – ${formatDate(apiDate(_range.end))}',
                ),
                onPressed: _pickRange,
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<SalesmanReport>>(
              future: _future,
              onRetry: _reload,
              builder: (context, list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.bar_chart_outlined,
                    message: 'ഈ period-ൽ data ഇല്ല',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ReportCard(rank: i + 1, r: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final int rank;
  final SalesmanReport r;
  const _ReportCard({required this.rank, required this.r});

  @override
  Widget build(BuildContext context) {
    final pct = r.targetAchievedPercent;
    final color = pct >= 100
        ? Colors.green
        : (pct >= 50 ? Colors.blue : Colors.orange);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (r.route.isNotEmpty)
                        Text(
                          r.route,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(r.totalSales),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat('Orders', '${r.totalOrders}'),
                _stat('Shops', '${r.shopsCovered}'),
                _stat('Present', '${r.attendanceDays} days'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Target ${formatMoney(r.monthlyTarget)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}
