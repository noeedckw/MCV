import 'package:flutter/material.dart';

class PageNav extends StatelessWidget {
  final IconData icon;
  final bool iconFirst;
  final String label;
  final VoidCallback? onTap;

  const PageNav({
    super.key,
    required this.icon,
    required this.iconFirst,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = Colors.white.withValues(alpha: enabled ? .85 : .22);

    final arrow = Padding(
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: color, size: 24),
    );
    final text = Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconFirst ? [arrow, text] : [text, arrow],
      ),
    );
  }
}