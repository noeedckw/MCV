// collection_album_detail_modal.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../storage/vinyl_entry.dart';
import '../../utils/artist_name.dart';
import '../cover_viewer_modal.dart';

Future<void> showCollectionAlbumDetail(
  BuildContext context, {
  required VinylEntry entry,
  required Widget cover,
  VoidCallback? onRemove,
  VoidCallback? onToggleList,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, anim1, anim2) => _CollectionAlbumDetailModal(
      entry: entry,
      cover: cover,
      onRemove: onRemove,
      onToggleList: onToggleList,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 20 * curved.value,
            sigmaY: 20 * curved.value,
          ),
          child: Container(
            color: Colors.black.withValues(alpha: .5 * curved.value),
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: .95, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Mirrors ResultCard's `_formatValue`: label peut être une List<String>
/// ou une string simple selon comment c'est stocké dans VinylEntry.
String? _formatLabelValue(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    if (value.isEmpty) return null;
    return value.join(' • ');
  }
  final str = value.toString();
  return str.isEmpty ? null : str;
}

class _CollectionAlbumDetailModal extends StatelessWidget {
  final VinylEntry entry;
  final Widget cover;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleList;

  const _CollectionAlbumDetailModal({
    required this.entry,
    required this.cover,
    required this.onRemove,
    required this.onToggleList,
  });

  @override
  Widget build(BuildContext context) {
    // Edition block is always shown, master included — mirrors the
    // large card's wording: "Master Release" when there's no specific
    // release tied to this entry, otherwise whatever format/country/date
    // is available for the chosen pressing.
    final versionParts = <String>[
      if (entry.format != null && entry.format!.isNotEmpty) entry.format!,
      if (entry.releaseCountry != null && entry.releaseCountry!.isNotEmpty)
        entry.releaseCountry!,
    ];
    final versionLabel = entry.isSpecificEdition
        ? (versionParts.isNotEmpty
              ? versionParts.join(' · ')
              : 'Specific Edition')
        : 'Master Release';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final modalWidth = constraints.maxWidth < 680
                ? constraints.maxWidth * 0.92
                : 600.0;
            final modalMaxHeight = (constraints.maxHeight - 32).clamp(
              280.0,
              680.0,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: SizedBox(
                    width: modalWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 280,
                        maxHeight: modalMaxHeight,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: _GlassPanel(
                          child: Stack(
                            children: [
                              _Content(
                                entry: entry,
                                cover: cover,
                                versionLabel: versionLabel,
                                isSpecificEdition: entry.isSpecificEdition,
                                onRemove: onRemove,
                                onToggleList: onToggleList,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: _CloseButton(
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF232329).withValues(alpha: .97),
                const Color(0xFF131316).withValues(alpha: .97),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .55),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.close_rounded,
            size: 19,
            color: Colors.white.withValues(alpha: .8),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.white.withValues(alpha: .40),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: .06),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .25,
          color: Colors.white.withValues(alpha: .70),
        ),
      ),
    );
  }
}

/// Small (i) icon with a tap-to-show tooltip. Reusable wherever a short
/// explanatory note needs to sit next to a value without cluttering the
/// layout.
class _InfoTooltip extends StatelessWidget {
  final String message;
  const _InfoTooltip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 5),
      preferBelow: true,
      verticalOffset: 14,
      constraints: const BoxConstraints(maxWidth: 220),
      textStyle: TextStyle(
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: .92),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF2A2A30).withValues(alpha: .98),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.info_outline_rounded,
        size: 14,
        color: Colors.white.withValues(alpha: .40),
      ),
    );
  }
}

/// Edition row: "EDITION" label + value.
/// - If they fit on one line, the value sits to the right of the label
///   (mirrors the large card's single-line badge).
/// - If not, the value drops to a new line below the label instead of
///   being squeezed / right-aligned against it (which looked broken).
/// - When the entry isn't tied to a specific pressing, a small (i) icon
///   sits right after the value; tapping it explains what "master
///   release" means, in English, matching the large card's wording.
class _EditionSection extends StatelessWidget {
  final String value;
  final bool isSpecific;

  const _EditionSection({required this.value, required this.isSpecific});

  static const String _label = 'EDITION';
  static const String _genericTooltip =
      "Generic release info\nNo specific edition selected.";
  static const double _spacing = 8;
  static const double _iconReserve = 20; // icon width + its own left spacing

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: Colors.white.withValues(alpha: .40),
    );
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
      height: 1.3,
      color: Colors.white.withValues(alpha: .85),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);

        final labelPainter = TextPainter(
          text: TextSpan(text: _label, style: labelStyle),
          textDirection: ui.TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final valuePainter = TextPainter(
          text: TextSpan(text: value, style: valueStyle),
          textDirection: ui.TextDirection.ltr,
          textScaler: scaler,
        )..layout();

        final needed =
            labelPainter.width +
            _spacing +
            valuePainter.width +
            (isSpecific ? 0 : _iconReserve);
        final fitsOneLine = needed <= constraints.maxWidth;

        final valueRow = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                textAlign: fitsOneLine ? TextAlign.right : TextAlign.left,
                style: valueStyle,
              ),
            ),
            if (!isSpecific) ...[
              const SizedBox(width: 4),
              _InfoTooltip(message: _genericTooltip),
            ],
          ],
        );

        if (fitsOneLine) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_label, style: labelStyle),
              const SizedBox(width: _spacing),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: valueRow),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label, style: labelStyle),
            const SizedBox(height: 3),
            valueRow,
          ],
        );
      },
    );
  }
}

/// Label collapsible : clampé à `_collapsedLines` lignes par défaut, avec
/// un toggle "Show more / Show less" — même comportement que dans la
/// modal de détail issue de la recherche (AlbumDetailModal).
class _LabelSection extends StatefulWidget {
  final String label;
  const _LabelSection({required this.label});

  @override
  State<_LabelSection> createState() => _LabelSectionState();
}

class _LabelSectionState extends State<_LabelSection> {
  static const int _collapsedLines = 2;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11.5,
      color: Colors.white.withValues(alpha: .45),
    );
    final text = 'Label : ${widget.label}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _collapsedLines,
          textDirection: ui.TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: SizedBox(
                width: double.infinity,
                child: Text(
                  text,
                  maxLines: _collapsedLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              secondChild: SizedBox(
                width: double.infinity,
                child: Text(text, style: style),
              ),
            ),
            if (overflows) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Compact glass action button used for Remove / Move-between-lists.
/// Neutral glass style throughout — no destructive/red variant.
class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: .78);
    return Material(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final VinylEntry entry;
  final Widget cover;
  final String versionLabel;
  final bool isSpecificEdition;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleList;

  const _Content({
    required this.entry,
    required this.cover,
    required this.versionLabel,
    required this.isSpecificEdition,
    required this.onRemove,
    required this.onToggleList,
  });

  @override
  Widget build(BuildContext context) {
    final genres = entry.genres ?? const [];
    final styles = entry.styles ?? const [];
    final tracklist = entry.tracklist ?? const [];
    final label = _formatLabelValue(entry.label);

    final toggleIcon = entry.isWantlist
        ? Icons.add_rounded
        : Icons.bookmark_border_rounded;
    final toggleLabel = entry.isWantlist
        ? 'Add to Collection'
        : 'Add to Wantlist';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => showCoverViewer(context, cover: cover),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 138,
                              height: 138,
                              child: cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cleanArtistName(entry.artist),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: .78),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -.3,
                              color: Colors.white,
                            ),
                          ),
                          if (entry.year != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              entry.year.toString(),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: .45),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (genres.isNotEmpty || styles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...genres.map(_Chip.new),
                    ...styles.map(_Chip.new),
                  ],
                ),
              ],
              // Edition block — always shown (generic master included),
              // neutral glass rectangle, no accent color. Value sits next
              // to "EDITION" when it fits on one line, otherwise it drops
              // to the line below. Generic/master entries get a small
              // (i) icon that explains what that means.
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: .06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: _EditionSection(
                  value: versionLabel,
                  isSpecific: isSpecificEdition,
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 10),
                _LabelSection(label: label),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: Colors.white12),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('TRACKLIST'),
                const SizedBox(height: 10),
                if (tracklist.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tracklist unavailable.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: .45),
                      ),
                    ),
                  )
                else
                  ...tracklist.map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              t.position,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: .40),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: .82),
                              ),
                            ),
                          ),
                          if (t.duration.isNotEmpty)
                            Text(
                              t.duration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: .40),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _SectionLabel('NOTES'),
                  const SizedBox(height: 10),
                  Text(
                    entry.notes!.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: .55),
                    ),
                  ),
                ],
                if (onRemove != null || onToggleList != null) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (onToggleList != null)
                        Expanded(
                          child: _GlassActionButton(
                            icon: toggleIcon,
                            label: toggleLabel,
                            onTap: onToggleList,
                          ),
                        ),
                      if (onRemove != null && onToggleList != null)
                        const SizedBox(width: 10),
                      if (onRemove != null)
                        Expanded(
                          child: _GlassActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Remove',
                            onTap: onRemove,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
