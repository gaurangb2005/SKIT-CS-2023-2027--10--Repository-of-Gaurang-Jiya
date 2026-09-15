import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/token_storage.dart';
import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  List<dynamic> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await Api.authedGet('/dashboard/admin');
      final users = await Api.authedGet('/users');
      final subjects = await Api.authedGet('/subjects');
      if (stats.statusCode != 200 || users.statusCode != 200 || subjects.statusCode != 200) {
        setState(() => _error = 'Could not load dashboard.');
        return;
      }
      setState(() {
        _stats = Api.decode(stats);
        _users = Api.decodeList(users);
        _subjects = Api.decodeList(subjects);
      });
    } catch (_) {
      setState(() => _error = 'Could not load dashboard. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final newState = !(user['is_active'] as bool);
    final res = await Api.authedPatch('/users/${user['id']}/active?is_active=$newState', {});
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() => user['is_active'] = newState);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update user')));
    }
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add subject'),
        content: AppTextField(label: 'Subject name', controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final res = await Api.authedPost('/subjects', {'name': name});
    if (!mounted) return;
    if (res.statusCode == 200) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add subject')));
    }
  }

  Future<void> _deleteSubject(int id) async {
    final res = await Api.authedDelete('/subjects/$id');
    if (!mounted) return;
    if (res.statusCode == 204) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete subject (it may still have content)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'Admin',
      items: const [NavItem(Icons.dashboard_rounded, 'Home')],
      currentIndex: 0,
      onTap: (_) {},
      actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => TokenStorage.logout(context))],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _stats == null) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: const [LoadingSkeleton(height: 90), SizedBox(height: Spacing.lg), LoadingSkeleton(height: 220)],
      );
    }
    if (_error != null && _stats == null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text('Admin Dashboard', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: Spacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 500 ? 2 : 4;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: Spacing.md,
                crossAxisSpacing: Spacing.md,
                childAspectRatio: 1.6,
                children: [
                  StatCard(label: 'Students', value: '${_stats?['students'] ?? 0}', icon: Icons.school_rounded),
                  StatCard(
                    label: 'Teachers',
                    value: '${_stats?['teachers'] ?? 0}',
                    icon: Icons.person_rounded,
                    color: AppColors.accent,
                  ),
                  StatCard(
                    label: 'Subjects',
                    value: '${_stats?['subjects'] ?? 0}',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    label: 'Content',
                    value: '${_stats?['content'] ?? 0}',
                    icon: Icons.description_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.add_circle_rounded), onPressed: _addSubject),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (_subjects.isEmpty)
            const EmptyState(icon: Icons.menu_book_rounded, message: 'No subjects yet. Add one above.')
          else
            for (final s in _subjects) ...[
              AppCard(
                child: Row(
                  children: [
                    Expanded(child: Text(s['name'].toString(), style: Theme.of(context).textTheme.titleMedium)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: () => _deleteSubject(s['id'] as int),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
          const SizedBox(height: Spacing.xl),
          Text('Users', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          if (_users.isEmpty)
            const EmptyState(icon: Icons.people_outline_rounded, message: 'No users yet.')
          else
            for (final u in _users) ...[
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (u['is_active'] as bool)
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person,
                        color: (u['is_active'] as bool) ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            u['name'].toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            u['role'].toString().toUpperCase(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: u['is_active'] as bool, onChanged: (_) => _toggleActive(u)),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
        ],
      ),
    );
  }
}
