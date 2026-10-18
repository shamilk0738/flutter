import 'package:flutter/material.dart';

import '../models/my_report.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class MyReportScreen extends StatefulWidget {
  const MyReportScreen({super.key});

  @override
  State<MyReportScreen> createState() => _MyReportScreenState();
}

class _MyReportScreenState extends State<MyReportScreen> {
  late DateTimeRange _range;
  late Future<MyReport> _future;
  int _mode = 1;

  @override
  void initState() {
    super.initState();
    _setMonth();
    _future = _fetch();
  }

  void _setToday() {
    final n = DateTime.now();
    final d = DateTime(n.year, n.month, n.day);
    _range = DateTimeRange(start: d, end: d);
  }

  void _setMonth() {
    final n = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(n.year, n.month, 1),
      end: DateTime(n.year, n.month, n.day),
    );
  }

  Future<MyReport> _fetch() =>
      Repository.instance.mySummary(from: _range.start, to: _range.end);

  Future<void> _reload() async {
    final result = _fetch();

    setState(() {
      _future = result;
    });
  }

  void _select(int mode) {
    _mode = mode;
    mode == 0 ? _setToday() : _setMonth();
    _reload();
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (r != null) {
      _mode = 2;
      _range = r;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My sales report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _mode == 0,
                    onSelected: (_) => _select(0),
                  ),
                  ChoiceChip(
                    label: const Text('This month'),
                    selected: _mode == 1,
                    onSelected: (_) => _select(1),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      '${formatDate(apiDate(_range.start))} – ${formatDate(apiDate(_range.end))}',
                    ),
                    onPressed: _pickRange,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<MyReport>(
              future: _future,
              onRetry: _reload,
              builder: (context, r) {
                if (r.count == 0) {
                  return const EmptyView(
                    icon: Icons.bar_chart_outlined,
                    message: 'No orders found for this period.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Kpi(
                            label: 'Total sales',
                            value: formatMoney(r.total),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Kpi(label: 'Orders', value: '${r.count}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (r.byDay.length > 1) _DayChart(days: r.byDay),
                    if (r.byShop.isNotEmpty) ...[
                      const _SectionTitle('Shop-wise'),
                      _RankCard(
                        items: [
                          for (final s in r.byShop)
                            _RankItem(
                              title: s.name,
                              subtitle: '${s.count} orders',
                              value: s.total,
                            ),
                        ],
                      ),
                    ],
                    if (r.byProduct.isNotEmpty) ...[
                      const _SectionTitle('Product-wise (pieces)'),
                      _RankCard(
                        items: [
                          for (final p in r.byProduct)
                            _RankItem(
                              title: p.name,
                              subtitle: [
                                if (p.brand.isNotEmpty) p.brand,
                                '${p.qty} pcs',
                                if (p.free > 0) '+${p.free} free',
                              ].join(' · '),
                              value: p.amount,
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  const _Kpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  );
}

class _DayChart extends StatelessWidget {
  final List<DayPoint> days;
  const _DayChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxV = days.fold<double>(0, (m, d) => d.total > m ? d.total : m);
    final color = Theme.of(context).colorScheme.primary;
    const chartHeight = 120.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Sales by day',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'Max ${formatMoney(maxV)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${formatDate(d.date)}\n${formatMoney(d.total)}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 28),
                              child: Container(
                                height: maxV == 0
                                    ? 2
                                    : (d.total / maxV * chartHeight).clamp(
                                        2.0,
                                        chartHeight,
                                      ),
                                decoration: BoxDecoration(
                                  color: d.total == 0
                                      ? color.withOpacity(0.15)
                                      : color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(days.first.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  formatDate(days.last.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankItem {
  final String title;
  final String subtitle;
  final double value;
  const _RankItem({
    required this.title,
    required this.subtitle,
    required this.value,
  });
}

class _RankCard extends StatelessWidget {
  final List<_RankItem> items;
  const _RankCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxV = items.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (final e in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                e.subtitle,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatMoney(e.value),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxV == 0 ? 0 : (e.value / maxV).clamp(0.0, 1.0),
                        minHeight: 5,
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
}
