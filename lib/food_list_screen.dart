import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:omakase_gohan/calendar_screen.dart';
import 'package:omakase_gohan/food_recipe_screen.dart';
import 'food_repository.dart';
import 'food_item.dart';
import 'app_navigation_bar.dart';
import 'food_add_screen.dart';
import 'category.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  //Variable
  String? _activeCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _daysUntil(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiry.difference(today).inDays;
  }

  String _groupLabel(int days) {
    if (days <= 1) return '賞味期限が近い';
    if (days <= 5) return 'もうすぐ';
    return 'まだ余裕あり';
  }

  Category _categoryOf(FoodItem item) => categories.firstWhere(
    (c) => c.name == item.category,
    orElse: () => const Category('その他', Color(0xFF9AA0A8), '🍽️'),
  );

  ({Color bg, Color fg, String label}) _badgeFor(int days) {
    if (days <= 0)
      return (
        bg: const Color(0x22E5484D),
        fg: const Color(0xFFB33B31),
        label: days == 0 ? '本日まで' : '期限切れ',
      );
    if (days <= 3)
      return (
        bg: const Color(0x22F59E0B),
        fg: const Color(0xFF9A6B1A),
        label: '後$days日',
      );
    return (
      bg: const Color(0x1A34A853),
      fg: const Color(0xFF2E7A4A),
      label: '後$days日',
    );
  }

  Future<void> _confirmDelete(FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${item.name}」を削除します。\nこの操作は取り消せません'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FoodRepository.delete(item);
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    final all = FoodRepository.getAll();

    final filtered = all.where((i) {
      final matchesCategory =
          _activeCategory == null || i.category == _activeCategory;
      final matchesSearch = i.name.contains(_searchController.text);
      return matchesCategory && matchesSearch;
    }).toList();

    filtered.sort((a, b) => a.expiry.compareTo(b.expiry));

    final Map<String, List<FoodItem>> groups = {};
    for (final item in filtered) {
      final label = _groupLabel(_daysUntil(item.expiry));
      groups.putIfAbsent(label, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '食材一覧',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${filtered.length}件の食材 ・ 賞味期限が近い順',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B9199),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9EBEE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF9AA0A8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '食材名で検索',
                          hintStyle: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFFA7ACB3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CategoryChip(
                    label: 'すべて',
                    color: const Color(0xFF9AA0A8),
                    selected: _activeCategory == null,
                    onTap: () => setState(() => _activeCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: c.name,
                        color: c.color,
                        selected: _activeCategory == c.name,
                        onTap: () => setState(() => _activeCategory = c.name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: groups.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B9199),
                          ),
                        ),
                      ),
                      ...entry.value.map(
                        (item) => GestureDetector(
                          onLongPress: () => _confirmDelete(item),
                          child: _FoodCard(
                            item: item,
                            category: _categoryOf(item),
                            badge: _badgeFor(_daysUntil(item.expiry)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FoodAddScreen()),
          );
        },
        backgroundColor: const Color(0xFF34A853),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecipeScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            );
          }
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: const Color(0xFFE9EbEE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF54595E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem item;
  final Category category;
  final ({Color bg, Color fg, String label}) badge;

  const _FoodCard({
    required this.item,
    required this.category,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(category.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF181A1C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.qty}個 ・ ${item.isShoumi ? "消費期限" : "賞味期限"}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9AA0A8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: badge.fg,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.expiry.year}/${item.expiry.month.toString().padLeft(2, '0')}/${item.expiry.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB3B8BF)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
