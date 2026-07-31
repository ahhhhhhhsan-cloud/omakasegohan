import 'package:hive_flutter/hive_flutter.dart';
import 'food_item.dart';

class FoodRepository {
  static Box<FoodItem> get _box => Hive.box<FoodItem>('foodBox');

  static Future<void> add(FoodItem item) async {
    await _box.add(item);
  }

  static List<FoodItem> getAll() {
    return _box.values.toList();
  }

  static Future<void> delete(FoodItem item) async {
    await item.delete();
  }
}
