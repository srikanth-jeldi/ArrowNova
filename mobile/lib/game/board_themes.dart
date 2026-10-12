import 'package:flutter/material.dart';

class BoardTheme {
  const BoardTheme(
    this.id,
    this.name,
    this.cost,
    this.dark,
    this.light,
    this.body,
    this.background,
  );
  final String id, name;
  final int cost;
  final Color dark, light, body, background;
}

const boardThemes = [
  BoardTheme(
    'crystal',
    'Crystal blue',
    0,
    Color(0xFF064681),
    Color(0xFF76E7FF),
    Color(0xFF098DEF),
    Color(0xFFEAF7FF),
  ),
  BoardTheme(
    'amethyst',
    'Amethyst',
    200,
    Color(0xFF472678),
    Color(0xFFE3C5FF),
    Color(0xFF9755E8),
    Color(0xFFF2EAFF),
  ),
  BoardTheme(
    'rose',
    'Rose quartz',
    400,
    Color(0xFF792858),
    Color(0xFFFFD1EB),
    Color(0xFFD858A3),
    Color(0xFFFFEDF6),
  ),
  BoardTheme(
    'sunset',
    'Golden sunset',
    600,
    Color(0xFF794A11),
    Color(0xFFFFE5A0),
    Color(0xFFD58C16),
    Color(0xFFFFF5DF),
  ),
];

BoardTheme boardTheme(String id) => boardThemes.firstWhere(
  (theme) => theme.id == id,
  orElse: () => boardThemes.first,
);
