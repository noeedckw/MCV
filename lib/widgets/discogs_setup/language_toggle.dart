import 'package:flutter/material.dart';

/// Toggle segmenté EN / FR.
///
/// Un seul tap n'importe où sur le composant bascule sur l'autre langue,
/// pas besoin de cibler précisément "EN" ou "FR".
class LanguageToggle extends StatelessWidget {
  final bool isFrench;
  final ValueChanged<bool> onChanged;

  const LanguageToggle({
    super.key,
    required this.isFrench,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isFrench),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Option(label: 'EN', active: !isFrench),
            _Option(label: 'FR', active: isFrench),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool active;

  const _Option({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
          color: active ? Colors.black : Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}