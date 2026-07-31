import 'package:flutter/material.dart';
import 'utils/date_picker_helper.dart';
import 'app_navigation_bar.dart';
import 'home_screen.dart';
import 'food_repository.dart';
import 'food_item.dart';
import 'app_colors.dart';
import 'category.dart';

class FoodAddScreen extends StatefulWidget {
  const FoodAddScreen({super.key});

  @override
  State<FoodAddScreen> createState() => _FoodAddScreenState();
}

class _FoodAddScreenState extends State<FoodAddScreen> {
  //Variable
  final _nameController = TextEditingController();
  int _qty = 1;
  String _category = '野菜';
  DateTime _expiry = DateTime.now();
  bool _isShoumi = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  //DaysLeft
  int get _daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_expiry.year, _expiry.month, _expiry.day);
    return target.difference(today).inDays;
  }

  //DaysLeftBadge
  (String, Color, Color) get _badge {
    final d = _daysLeft;
    if (d < 0)
      return ('期限切れ', const Color(0xFFFDECEC), const Color(0xFFE5484D));
    if (d == 0)
      return ('今日まで', const Color(0xFFFDECEC), const Color(0xFFE5484D));
    if (d <= 3)
      return ('あと$d日', const Color(0xFFFDECEC), const Color(0xFFE5484D));
    if (d <= 7)
      return ('あと$d日', const Color(0xFFFFF3E0), const Color(0xFFC77700));
    return ('あと$d日', accentSoft, accentInk);
  }

  //DateText
  String get _dateText =>
      '${_expiry.year}/${_expiry.month.toString().padLeft(2, '0')}/${_expiry.day.toString().padLeft(2, '0')}';

  //OpenCalender
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  //SubmitButton
  void _submit() {
    final newItem = FoodItem(
      name: _nameController.text,
      qty: _qty,
      category: _category,
      expiry: _expiry,
      isShoumi: _isShoumi,
    );

    FoodRepository.add(newItem);
    debugPrint('現在の保存件数: ${FoodRepository.getAll().length}');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          duration: const Duration(milliseconds: 1800),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF5EDE93),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_nameController.text.isEmpty ? '食材' : _nameController.text}を追加しました',
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final (badgeText, badgeBg, badgeFg) = _badge;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: const BackButton(color: ink),
        title: const Text(
          '食材を追加',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Name
            Container(
              decoration: BoxDecoration(
                color: fillFocus,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: accent, width: 1.5),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '名前',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 16, color: ink),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '食材名を入力',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            //Quantity
            Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '数量',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ink2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_qty 個',
                          style: const TextStyle(fontSize: 16, color: ink),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE4E7E0)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _stepBtn(
                          Icons.remove,
                          fill,
                          ink2,
                          () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$_qty',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                        _stepBtn(
                          Icons.add,
                          accent,
                          Colors.white,
                          () => setState(() => _qty++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            //BestBeforeDate
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _pickDate,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isShoumi ? '賞味期限' : '消費期限',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ink2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateText,
                            style: const TextStyle(fontSize: 16, color: ink),
                          ),
                        ],
                      ),
                    ),
                    //DaysRemainingBadge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    //BestBeforeUseBySwitchButton
                    GestureDetector(
                      onTap: () => setState(() => _isShoumi = !_isShoumi),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accentSoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _isShoumi ? '賞味' : '消費',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    //CalendarIcon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: accent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            //Category
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 9),
              child: Text(
                'カテゴリ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ink2,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final on = c.name == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: on ? accent : fill,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: on ? Colors.white : c.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                            color: on ? Colors.white : const Color(0xFF4A4F47),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            //AddButton
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, size: 22),
                label: const Text(
                  '追加する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),

      //NavigationBar
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  //StepperButton
  Widget _stepBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: fg),
      ),
    );
  }
}
