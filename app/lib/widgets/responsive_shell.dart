import 'package:flutter/material.dart';

import 'widgets.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

/// Breakpoints: <600 phone (bottom nav), 600-1024 tablet (rail), >1024 desktop (sidebar).
class ResponsiveShell extends StatelessWidget {
  final String title;
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;
  final List<Widget>? actions;

  const ResponsiveShell({
    super.key,
    required this.title,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (items.length <= 1) {
          return _SimpleScaffold(title: title, actions: actions, body: body);
        }
        if (width < 600) return _MobileScaffold(title: title, actions: actions, body: body, items: items, currentIndex: currentIndex, onTap: onTap);
        if (width < 1024) return _TabletScaffold(title: title, actions: actions, body: body, items: items, currentIndex: currentIndex, onTap: onTap);
        return _DesktopScaffold(title: title, actions: actions, body: body, items: items, currentIndex: currentIndex, onTap: onTap);
      },
    );
  }
}

class _SimpleScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  const _SimpleScaffold({required this.title, required this.actions, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: CenteredMaxWidth(child: body),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MobileScaffold({
    required this.title,
    required this.actions,
    required this.body,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: [for (final i in items) BottomNavigationBarItem(icon: Icon(i.icon), label: i.label)],
      ),
    );
  }
}

class _TabletScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabletScaffold({
    required this.title,
    required this.actions,
    required this.body,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            destinations: [for (final i in items) NavigationRailDestination(icon: Icon(i.icon), label: Text(i.label))],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DesktopScaffold({
    required this.title,
    required this.actions,
    required this.body,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        ListTile(
                          leading: Icon(items[i].icon, color: i == currentIndex ? colorScheme.primary : null),
                          title: Text(
                            items[i].label,
                            style: TextStyle(
                              color: i == currentIndex ? colorScheme.primary : null,
                              fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          selected: i == currentIndex,
                          selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
                          onTap: () => onTap(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
                  ),
                Expanded(child: CenteredMaxWidth(child: body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
