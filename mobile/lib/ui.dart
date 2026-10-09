import 'package:flutter/material.dart';

const navy = Color(0xFF071B33);
const gold = Color(0xFFEAC77B);
const ice = Color(0xFFEDF4F8);
const muted = Color(0xFF9FB5CC);

/// Adapted from ChessVerseButton's gradient wrapper and disabled-action pattern.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFEABB), Color(0xFFE2BC70), Color(0xFFBD8F43)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: Border.all(color: const Color(0xFFFFE7AC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x303DA9DD),
          blurRadius: 22,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 24), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class BoardControl extends StatelessWidget {
  const BoardControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: gold),
          gradient: const LinearGradient(
            colors: [Color(0xFF264D6C), navy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33071B33),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon),
          color: gold,
          disabledColor: muted,
          iconSize: 25,
          padding: const EdgeInsets.all(12),
        ),
      ),
      const SizedBox(height: 7),
      Text(label, style: const TextStyle(color: navy, fontSize: 12)),
    ],
  );
}

class Atmosphere extends StatelessWidget {
  const Atmosphere({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.5),
        radius: 1.2,
        colors: [Color(0xFF153C5C), Color(0xFF071B33), Color(0xFF030D1B)],
      ),
    ),
    child: child,
  );
}
