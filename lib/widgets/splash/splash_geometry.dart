import 'dart:math' as math;

/// Géométrie du disque vinyle et du logo, calculée à partir de la taille
/// de l'écran. Les mêmes ratios sont utilisés par les painters
/// (VinylGroovePainter / SpinningVinylPainter) pour garantir que le logo
/// tombe pile sur le rond central quelle que soit la taille de l'écran.
class SplashGeometry {
  // Fraction verticale du centre du vinyle (utilisée à la fois par le
  // painter du disque ET par le positionnement du logo, pour qu'ils
  // soient garantis alignés peu importe la taille de l'écran).
  static const double vinylCenterYFraction = 0.42;

  // Ratio entre le rayon du disque et le "longestSide" du conteneur
  // (même valeur que dans SpinningVinylPainter / VinylGroovePainter).
  static const double discRadiusRatio = 0.62;

  // Ratio entre le rayon du label central et le rayon du disque (même
  // valeur que dans SpinningVinylPainter).
  static const double labelRadiusRatio = 0.22;

  // Le logo doit être légèrement plus petit que le rond du label, pour
  // matcher visuellement sans le déborder. 1.0 = taille identique.
  static const double logoToLabelRatio = 0.75;

  final double vinylCenterY;
  final double discRadius;
  final double labelRadius;
  final double logoSize;
  final double glowSize;

  SplashGeometry._({
    required this.vinylCenterY,
    required this.discRadius,
    required this.labelRadius,
    required this.logoSize,
    required this.glowSize,
  });

  factory SplashGeometry.of(double width, double height) {
    final vinylCenterY = height * vinylCenterYFraction;
    final discRadius = math.max(width, height) * discRadiusRatio;
    final labelRadius = discRadius * labelRadiusRatio;
    final logoSize = labelRadius * 2 * logoToLabelRatio;
    // Glow proportionnel au logo (même ratio qu'avant : 400 / 140 ≈ 2.85).
    final glowSize = logoSize * 2.85;

    return SplashGeometry._(
      vinylCenterY: vinylCenterY,
      discRadius: discRadius,
      labelRadius: labelRadius,
      logoSize: logoSize,
      glowSize: glowSize,
    );
  }
}