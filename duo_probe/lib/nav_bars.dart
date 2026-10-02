import 'package:flutter/material.dart';

import 'theme.dart';

void Function(String message)? navBarLog;

class NavBarsPage extends StatelessWidget {
  const NavBarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    return DefaultTabController(
      length: 4,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 150),
        children: [
          Panel(
            title: 'issue #193035 — which widget?',
            children: [
              Text(
                'The issue says "tab bar". Flutter has four candidates and they '
                'are different widgets. Each is rendered below at full available '
                'width, and reports the width it actually occupied.\n\n'
                'Screen width: $screen lp',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: kMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const _Measured(
            label: 'TabBar (in AppBar)',
            child: _TabBarSample(inAppBar: true),
          ),
          const _Measured(label: 'TabBar (bare)', child: _TabBarSample()),
          const _Measured(
            label: 'NavigationBar (Material 3)',
            child: _NavigationBarSample(),
          ),
          const _Measured(
            label: 'BottomNavigationBar (fixed)',
            child: _BottomNavSample(),
          ),
        ],
      ),
    );
  }
}

class _Measured extends StatelessWidget {
  const _Measured({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    return Panel(
      title: label,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final key = GlobalKey();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final box = key.currentContext?.findRenderObject();
              if (box is RenderBox && box.hasSize) {
                navBarLog?.call(
                  'navbar "$label" rendered ${box.size.width} x ${box.size.height} '
                  'available=${constraints.maxWidth} screenWidth=$screen '
                  'fillsAvailable=${box.size.width == constraints.maxWidth}',
                );
              }
            });
            return SizedBox(key: key, child: child);
          },
        ),
      ],
    );
  }
}

class _TabBarSample extends StatelessWidget {
  const _TabBarSample({this.inAppBar = false});

  final bool inAppBar;

  @override
  Widget build(BuildContext context) {
    const bar = TabBar(
      tabs: [
        Tab(text: 'One'),
        Tab(text: 'Two'),
        Tab(text: 'Three'),
        Tab(text: 'Four'),
      ],
    );
    if (!inAppBar) return const SizedBox(height: 48, child: bar);
    return SizedBox(
      height: 48,
      child: AppBar(
        backgroundColor: kPanelAlt,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: bar,
        ),
      ),
    );
  }
}

class _NavigationBarSample extends StatelessWidget {
  const _NavigationBarSample();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      backgroundColor: kPanelAlt,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.analytics), label: 'One'),
        NavigationDestination(icon: Icon(Icons.layers), label: 'Two'),
        NavigationDestination(icon: Icon(Icons.aspect_ratio), label: 'Three'),
        NavigationDestination(icon: Icon(Icons.save), label: 'Four'),
      ],
    );
  }
}

class _BottomNavSample extends StatelessWidget {
  const _BottomNavSample();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: kPanelAlt,
      selectedItemColor: kAccent,
      unselectedItemColor: kMuted,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'One'),
        BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Two'),
        BottomNavigationBarItem(icon: Icon(Icons.aspect_ratio), label: 'Three'),
        BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Four'),
      ],
    );
  }
}
