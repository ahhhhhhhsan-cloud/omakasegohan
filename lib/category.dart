import 'package:flutter/material.dart';

//CategoryDefinitions
class Category {
  final String name;
  final Color color;
  final String icon;

  const Category(this.name, this.color, this.icon);
}

const categories = <Category>[
  Category('野菜', Color(0xFF34A853),'🥬'),
  Category('肉', Color(0xFFE5484D),'🍗'),
  Category('魚', Color(0xFF3B82F6),'🐟'),
  Category('果物', Color(0xFFF59E0B),'🍎'),
  Category('乳製品', Color(0xFFBFBAB8),'🍶'),
  Category('冷凍食品', Color(0xFF5AC8E8),'🧊'),
  Category('調味料', Color(0xFF8F76F0),'🧂'),
];
