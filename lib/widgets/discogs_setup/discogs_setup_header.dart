import 'package:flutter/material.dart';

import '../../../widgets/app_logo.dart';
import '../../screens/discogs_setup/discogs_setup_strings.dart';
import 'language_toggle.dart';

/// En-tête de l'écran : libellé "MY COLLECTION OF VINYL" à gauche, logo au
/// centre, toggle de langue à droite.
class DiscogsSetupHeader extends StatelessWidget {
  final DiscogsSetupStrings strings;
  final bool isFrench;
  final ValueChanged<bool> onLanguageChanged;

  const DiscogsSetupHeader({
    super.key,
    required this.strings,
    required this.isFrench,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CollectionLabel(strings: strings),
            ),
          ),
          const AppLogo(size: 68),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: LanguageToggle(
                isFrench: isFrench,
                onChanged: onLanguageChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionLabel extends StatelessWidget {
  final DiscogsSetupStrings strings;

  const _CollectionLabel({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.headerLine1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        Text(
          strings.headerLine2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        Text(
          strings.headerLine3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}