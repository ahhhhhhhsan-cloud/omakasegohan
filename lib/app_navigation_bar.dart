import'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
});
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'ホーム',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu),
          label: 'レシピ',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month),
          label: 'カレンダー',
        ),
      ],
    );
  }
}