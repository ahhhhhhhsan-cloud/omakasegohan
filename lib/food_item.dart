import 'package:hive/hive.dart';

part 'food_item.g.dart';

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int qty;

  @HiveField(2)
  String category;

  @HiveField(3)
  DateTime expiry;

  @HiveField(4)
  bool isShoumi;

  FoodItem({
    required this.name,
    required this.qty,
    required this.category,
    required this.expiry,
    required this.isShoumi,
});
}