import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'app_navigation_bar.dart';
import 'food_add_screen.dart';
import 'food_list_screen.dart';
import 'app_colors.dart';
import 'food_recipe_screen.dart';
import 'calendar_screen.dart';
import 'food_repository.dart';
import 'food_item.dart';

// ダッシュボード型ホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _daysUntil(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiry.year, expiry.month, expiry.day);
    return target.difference(today).inDays;
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => setState(() {})); //戻ってきたら件数を更新
  }

  @override
  Widget build(BuildContext context) {
    final all = FoodRepository.getAll();
    // 期限３日以内の食材 (近い順)
    final urgentItems = all.where((i) => _daysUntil(i.expiry) <= 3).toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    final now = DateTime.now();
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'こんにちは 👋',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${now.month}月${now.day}日 (${weekdays[now.weekday - 1]}) ・冷蔵庫に${all.length}品あります',
                    style: const TextStyle(fontSize: 13, color: ink2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _urgentCard(urgentItems),
                  const SizedBox(height: 14),
                  _recipeBanner(urgentItems.length),
                  const SizedBox(height: 14),
                  _lastRecipeCard(),
                  //Shortcuts
                  Row(
                    children: [
                      Expanded(
                        child: _shortcutCard(
                          icon: Icons.add_circle,
                          iconColor: accent,
                          iconBg: accentSoft,
                          title: '食材を追加',
                          subtitle: '買ってきたものを登録',
                          onTap: () => _push(FoodAddScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _shortcutCard(
                          icon: Icons.calendar_month,
                          iconColor: const Color(0xFF4A6FB5),
                          iconBg: const Color(0xFFE9EEF9),
                          title: 'カレンダー',
                          subtitle: '期限をひと目で確認',
                          onTap: () => _push(const CalendarScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) _push(const RecipeScreen());
          if (index == 2) _push(const CalendarScreen());
        },
      ),
    );
  }

  //UrgentCard (期限が近い食材)
  Widget _urgentCard(List<FoodItem> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule, size: 17, color: Color(0xFFB33B31)),
                  SizedBox(width: 7),
                  Text(
                    '期限が近い食材',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ],
              ),
              Text(
                '${items.length}件',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: items.isNotEmpty ? const Color(0xFFB33B31) : ink2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '3日以内に期限を迎える食材はありません',
                style: TextStyle(fontSize: 12.5, color: ink2),
              ),
            ),
          ...items.map(_urgentRow),
          const Divider(height: 22, color: Color(0xFFF0F1F3)),
          //食材一覧へ
          InkWell(
            onTap: () => _push(FoodListScreen()),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '食材一覧を見る',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accentInk,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: accentInk),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgentRow(FoodItem item) {
    final days = _daysUntil(item.expiry);
    final urgent = days <= 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF33373B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: urgent ? const Color(0xFFFDECEC) : const Color(0xFFFBF3ED),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              days <= 0 ? '今日まで' : 'あと$days日',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: urgent
                    ? const Color(0xFFB33B31)
                    : const Color(0xFF9A6B1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //RecipeBanner (緑のレシピ提案ボタン)
  Widget _recipeBanner(int urgentCount) {
    return InkWell(
      onTap: () => _push(const RecipeScreen()),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D5C33),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urgentCount > 0
                        ? 'この$urgentCount つでレシピを提案してもらう'
                        : 'レシピを提案して',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '期限が近い食材をムダなく使い切る',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  //LastRecipeCard (前回のレシピ。まだなければ何も表示しない)
  Widget _lastRecipeCard() {
    final settingsBox = Hive.box('settingsBox');
    final String? lastRecipe = settingsBox.get('lastRecipe');
    if (lastRecipe == null || lastRecipe.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDEFF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant, size: 17, color: accent),
                  SizedBox(width: 7),
                  Text(
                    '前回のレシピ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 2行で省略表示
              Text(
                lastRecipe,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: Color(0xFF54595E),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _push(const RecipeScreen()),
                child: const Row(
                  children: [
                    Text(
                      'つづきを読む',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accentInk,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: accentInk),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  //ShortcutCard
  Widget _shortcutCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: ink2)),
          ],
        ),
      ),
    );
  }
}
