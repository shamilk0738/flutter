import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/format.dart';
import 'attendance_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('ഈ device-ൽ നിന്ന് log out ചെയ്യണോ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final initial = user.name.isEmpty ? '?' : user.name[0].toUpperCase();
    final photo = user.photo;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    // Photo ഉണ്ടെങ്കിൽ അത്; load ആയില്ലെങ്കിൽ താഴെയുള്ള initial കാണും
                    foregroundImage: hasPhoto ? NetworkImage(photo) : null,
                    onForegroundImageError: hasPhoto ? (_, __) {} : null,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(capitalize(user.role)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (user.phone.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Phone'),
                    subtitle: Text(user.phone),
                  ),
                if (user.route.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.alt_route),
                    title: const Text('Route'),
                    subtitle: Text(user.route),
                  ),
                if (user.isSalesman || user.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Attendance'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
