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
    'Level colours',
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

const levelPalettes = [
  BoardTheme(
    'blue',
    'Ocean blue',
    0,
    Color(0xFF064681),
    Color(0xFF76E7FF),
    Color(0xFF098DEF),
    Color(0xFFEAF7FF),
  ),
  BoardTheme(
    'green',
    'Emerald green',
    0,
    Color(0xFF064D36),
    Color(0xFF96F3C2),
    Color(0xFF139F67),
    Color(0xFFEDF9F2),
  ),
  BoardTheme(
    'black',
    'Graphite black',
    0,
    Color(0xFF101820),
    Color(0xFFAEBFCF),
    Color(0xFF344454),
    Color(0xFFF1F5F9),
  ),
];

/// Keep a level's colour stable across retries and saved-game restoration.
/// Explicitly selected purchased themes still override the free rotation.
BoardTheme levelBoardTheme(String selected, int level) => selected == 'crystal'
    ? levelPalettes[((level < 1 ? 1 : level) - 1) % levelPalettes.length]
    : boardTheme(selected);
