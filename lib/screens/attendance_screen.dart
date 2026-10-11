import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/attendance.dart';
import '../providers/auth_provider.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime? _date;
  late Future<List<Attendance>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Attendance>> _fetch() =>
      Repository.instance.attendance(date: _date);

  void _reload() => setState(() => _future = _fetch());

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2024),
      lastDate: now,
    );
    if (d != null) {
      _date = d;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          if (_date != null)
            IconButton(
              tooltip: 'Clear date',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () {
                _date = null;
                _reload();
              },
            ),
          IconButton(
            tooltip: 'Filter by date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_date != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(formatDate(apiDate(_date!))),
                  onDeleted: () {
                    _date = null;
                    _reload();
                  },
                ),
              ),
            ),
          Expanded(
            child: AsyncBody<List<Attendance>>(
              future: _future,
              onRetry: _reload,
              builder: (context, list) {
                if (list.isEmpty) {
                  return const EmptyView(
                      icon: Icons.event_busy_outlined,
                      message: 'Attendance records ഇല്ല');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final a = list[i];
                    final t = DateTime.tryParse(a.loginTime)?.toLocal();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: Icon(Icons.check_circle_outline,
                              color: Colors.green.shade700),
                        ),
                        title: Text(user.isAdmin
                            ? a.salesmanName
                            : formatDate(a.date)),
                        subtitle: Text(user.isAdmin ? formatDate(a.date) : 'Logged in'),
                        trailing: Text(t == null ? '-' : formatTime(t),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
