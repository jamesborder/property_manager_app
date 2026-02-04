import 'package:flutter/material.dart';

enum ColorGroup {
  brown(
    displayName: 'Brown',
    color: Color(0xFF8B4513),
    propertyCount: 2,
    houseCost: 50,
  ),
  lightBlue(
    displayName: 'Light Blue',
    color: Color(0xFFADD8E6),
    propertyCount: 3,
    houseCost: 50,
  ),
  pink(
    displayName: 'Pink',
    color: Color(0xFFD93A96),
    propertyCount: 3,
    houseCost: 100,
  ),
  orange(
    displayName: 'Orange',
    color: Color(0xFFFFA500),
    propertyCount: 3,
    houseCost: 100,
  ),
  red(
    displayName: 'Red',
    color: Color(0xFFFF0000),
    propertyCount: 3,
    houseCost: 150,
  ),
  yellow(
    displayName: 'Yellow',
    color: Color(0xFFFFFF00),
    propertyCount: 3,
    houseCost: 150,
  ),
  green(
    displayName: 'Green',
    color: Color(0xFF008000),
    propertyCount: 3,
    houseCost: 200,
  ),
  darkBlue(
    displayName: 'Dark Blue',
    color: Color(0xFF0000FF),
    propertyCount: 2,
    houseCost: 200,
  ),
  railroad(
    displayName: 'Railroad',
    color: Color(0xFF000000),
    propertyCount: 4,
    houseCost: 0,
  ),
  utility(
    displayName: 'Utility',
    color: Color(0xFF808080),
    propertyCount: 2,
    houseCost: 0,
  );

  const ColorGroup({
    required this.displayName,
    required this.color,
    required this.propertyCount,
    required this.houseCost,
  });

  final String displayName;
  final Color color;
  final int propertyCount;
  final int houseCost;

  bool get isStreet => this != railroad && this != utility;
}
