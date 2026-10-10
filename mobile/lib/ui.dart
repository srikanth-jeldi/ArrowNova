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
          border: Border.all(color: const Color(0xFF64DBFF), width: 2),
          gradient: const LinearGradient(
            colors: [Color(0xFF376C96), Color(0xFF103E6B), Color(0xFF041B38)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x554ABEFF),
              blurRadius: 9,
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
          iconSize: 28,
          padding: const EdgeInsets.all(12),
        ),
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: const TextStyle(
          color: navy,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class GlossyHeart extends StatelessWidget {
  const GlossyHeart({super.key, required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 36,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 34,
          color: filled ? const Color(0xFFC91749) : const Color(0xFF98A8B7),
          shadows: filled
              ? const [
                  Shadow(
                    color: Color(0x55E62B63),
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        if (filled) ...[
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF98B7), Color(0xFFFF255D), Color(0xFFD90945)],
            ).createShader(bounds),
            child: const Icon(
              Icons.favorite_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 8,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xDDFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    ),
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
