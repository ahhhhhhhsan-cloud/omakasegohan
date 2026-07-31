import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'app_colors.dart';
import 'food_repository.dart';
import 'food_item.dart';
import 'app_navigation_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  //Variable
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  //日付ごとに食材をまとめたMap (マーカー表示に使う)
  late Map<DateTime, List<FoodItem>> _byDate;

  @override
  void initState() {
    super.initState();
    _byDate = {};
    for (final item in FoodRepository.getAll()) {
      final d = _dateOnly(item.expiry);
      _byDate.putIfAbsent(d, () => []).add(item);
    }
  }

  // 時刻を切り捨てて「日付だけ」にする (Mapのキー比較用)
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<FoodItem> _itemsOn(DateTime day) => _byDate[_dateOnly(day)] ?? [];

  int _daysUntil(DateTime expiry) {
    final today = _dateOnly(DateTime.now());
    return _dateOnly(expiry).difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsOn(_selectedDay);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'カレンダー',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '食材の賞味期限をひと目で確認できます',
                    style: TextStyle(fontSize: 13, color: ink2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _calendarCard(),
                  const SizedBox(height: 14),
                  //SelectedDDayHeader
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDay.month}月${_selectedDay.day}日に期限の食材',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        Text(
                          '${items.length}件',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: items.isNotEmpty ? accentInk : ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty) _emptyCard(),
                  ...items.map(_foodCard),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 2, //カレンダタブ
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  //CalendarCard
  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: TableCalendar<FoodItem>(
        locale: 'ja_JP',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        // ここが賞味期限のマーカーの肝 : 日付ごとの食材リストを返す
        eventLoader: _itemsOn,
        //Header
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          // 「2 weeks」 切り替えボタンを消す
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: ink2),
          rightChevronIcon: Icon(Icons.chevron_right, color: ink2),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ink2,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC56760),
          ),
        ),
        //CalendarStyle(今日・選択日・マーカーの色)
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          todayDecoration: BoxDecoration(
            color: accentSoft,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: accentInk,
            fontWeight: FontWeight.w700,
          ),
          markerDecoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 5,
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  //FoodCard
  Widget _foodCard(FoodItem item) {
    final days = _daysUntil(item.expiry);
    final badgeText = days < 0
        ? '期限切れ'
        : days == 0
        ? '今日まで'
        : 'あと$days日';
    final urgent = days <= 1;
    final warn = days <= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  Text(
                    '${item.qty}',
                    style: const TextStyle(fontSize: 11.5, color: ink2),
                  ),
                ],
              ),
            ),
            //Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: urgent
                    ? const Color(0xFFFDECEC)
                    : warn
                    ? const Color(0xFFFBF3E0)
                    : const Color(0xFFEFF1F4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: urgent
                      ? const Color(0xFFB33B31)
                      : warn
                      ? const Color(0xFF9A6B1A)
                      : const Color(0xFF6B7076),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //EmptyCard
  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE0E5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available, size: 26, color: Color(0xFFC3C8CE)),
          SizedBox(height: 10),
          Text(
            'この日に期限を迎える食材はありません',
            style: TextStyle(fontSize: 12.5, color: ink2),
          ),
        ],
      ),
    );
  }
}
