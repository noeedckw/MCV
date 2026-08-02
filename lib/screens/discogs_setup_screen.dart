import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/discogs_auth_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_container.dart';
import '../widgets/onboarding_carousel.dart';

class DiscogsSetupScreen extends StatefulWidget {
  final TokenStorageService tokenStorageService;
  final VoidCallback onConfigured;

  const DiscogsSetupScreen({
    super.key,
    required this.tokenStorageService,
    required this.onConfigured,
  });

  @override
  State<DiscogsSetupScreen> createState() => _DiscogsSetupScreenState();
}

class _DiscogsSetupScreenState extends State<DiscogsSetupScreen> {
  final _controller = TextEditingController();
  final _authService = DiscogsAuthService();

  bool _isLoading = false;
  bool _isFrench = false; // anglais par défaut, switchable juste pour cet écran
  String? _errorMessage;
  String? _successMessage;

  /// Petit helper de traduction locale à l'écran : _s(anglais, français)
  String _s(String en, String fr) => _isFrench ? fr : en;

  // Chemins d'image des étapes : avant définis dans OnboardingVisuals
  // (supprimé lors du rework), maintenant ici puisque c'est le seul
  // endroit qui les utilise.
  static const String _step1Image = 'assets/images/setup/discogs_create_account.png';

  // Steps 2 et 3 : image différente selon la langue (ex. capture d'écran
  // avec du texte visible dessus). TODO: remplacer ces noms placeholder
  // par les vrais assets et les déclarer dans pubspec.yaml
  // (flutter: assets:) avant de relancer l'app.
  static const String _step2ImageEn = 'assets/images/setup/generate_token_eng.png';
  static const String _step2ImageFr = 'assets/images/setup/generate_token_fr.png';
  static const String _step3ImageEn = 'assets/images/setup/copy_token_eng.jpeg';
  static const String _step3ImageFr = 'assets/images/setup/copy_token_fr.jpeg';

  String get _step2Image => _s(_step2ImageEn, _step2ImageFr);
  String get _step3Image => _s(_step3ImageEn, _step3ImageFr);

  List<OnboardingStep> get _steps => [
      OnboardingStep(
        title: _s('Create a Discogs account', 'Créez un compte Discogs'),
        description: _s(
          "Create a free Discogs account if you don't already have one.",
          "Créez gratuitement un compte Discogs si vous n'en avez pas encore un.",
        ),
        imageUrl: _step1Image,
        imagePosition: OnboardingImagePosition.left,
        imageWidth: 100,
        imageHeight: 170,
        cardWidth: 270,
        cardHeight: 200,
        cardPadding: const EdgeInsets.all(14),
      ),
      OnboardingStep(
        title: _s('Go to Developer Settings', 'Paramètres développeur'),
        description: _s(
          'Click the "Generate new token" button.',
          'Appuyez sur « Générer un nouveau jeton ».',
        ),
        imageUrl: _step2Image,
        imagePosition: OnboardingImagePosition.right,
        imageHeight: 115,
        imageWidth: 165,
        cardWidth: 345,
        cardHeight: 145,
        cardPadding: const EdgeInsets.all(12),
      ),
      OnboardingStep(
        title: _s('Copy your token', 'Copiez votre jeton'),
        description: _s(
          'Copy the value shown after \n"Current token: "and paste it below.',
          "Copiez la valeur affichée après \n« Jeton actuel : » puis collez-la ci-dessous.",
        ),
        imageUrl: _step3Image,
        imagePosition: OnboardingImagePosition.below,
        imageHeight: 80,
        cardWidth: 230,
        cardHeight: 210,
        cardPadding: const EdgeInsets.all(14),
      ),
      OnboardingStep(
        title: _s('Verify & enjoy', 'Vérifiez et profitez'),
        description: _s(
          'Verify your token and start using the app.',
          'Vérifiez votre jeton puis profitez de l\u2019application.',
        ),
        cardHeight: 100,
        cardWidth: 280,
        cardPadding: const EdgeInsets.all(16),
      ),
    ];

  bool _otherLangPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_otherLangPrecached) {
      _otherLangPrecached = true;
      _precacheOtherLanguageImages();
    }
  }

  Future<void> _precacheOtherLanguageImages() async {
    final otherLangPaths = _isFrench
        ? [_step2ImageEn, _step3ImageEn]
        : [_step2ImageFr, _step3ImageFr];
    for (final path in otherLangPaths) {
      await precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDiscogsSettings() async {
    final uri = Uri.parse('https://www.discogs.com/settings/developers');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      setState(() => _errorMessage = _s(
            "Couldn't open the browser.",
            "Impossible d'ouvrir le navigateur.",
          ));
    }
  }

  /// Traduit le résultat de validation Discogs dans la langue active de
  /// l'écran, en se basant sur `result.status` (enum) plutôt que sur
  /// `result.message` (toujours en français côté service).
  String _localizeError(DiscogsTokenValidationResult result) {
    switch (result.status) {
      case DiscogsTokenValidationStatus.empty:
        return _s(
          'Please enter your Discogs key.',
          'Veuillez saisir votre clé Discogs.',
        );
      case DiscogsTokenValidationStatus.unauthorized:
        return _s(
          'This Discogs key is invalid. Check it or create a new one.',
          'Cette clé Discogs est invalide. Vérifiez votre clé ou créez-en une nouvelle.',
        );
      case DiscogsTokenValidationStatus.forbidden:
        return _s(
          'Access denied by Discogs. Check your key permissions.',
          'Accès refusé par Discogs. Vérifiez les permissions de votre clé.',
        );
      case DiscogsTokenValidationStatus.network:
        return _s(
          "Couldn't reach Discogs. Check your internet connection.",
          "Impossible de contacter Discogs. Vérifiez votre connexion internet.",
        );
      case DiscogsTokenValidationStatus.unknown:
        return result.statusCode != null
            ? _s(
                'Discogs error (code ${result.statusCode}). Try again later.',
                'Erreur Discogs (code ${result.statusCode}). Réessayez plus tard.',
              )
            : _s(
                'A Discogs error occurred. Try again later.',
                'Une erreur Discogs est survenue. Réessayez plus tard.',
              );
      case DiscogsTokenValidationStatus.valid:
        return ''; // ne devrait jamais être affiché (cas géré à part)
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.validateToken(_controller.text);
    if (!mounted) return;

    if (result.isValid) {
      await widget.tokenStorageService.saveToken(_controller.text.trim());
      setState(() {
        _isLoading = false;
        _successMessage = result.username != null
            ? _s('Connected as ${result.username}.',
                'Connecté en tant que ${result.username}.')
            : _s('Connection successful.', 'Connexion réussie.');
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) widget.onConfigured();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = _localizeError(result);
      });
    }
  }

  @override
Widget build(BuildContext context) {
  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
  final keyboardVisible = bottomInset > 0;

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.6),
            radius: 1.4,
            colors: [Color(0xFF221F2B), Color(0xFF121114)],
          ),
        ),
        child: SafeArea(
          // NOUVEAU : compense manuellement le clavier (resizeToAvoidBottomInset
          // est à false). Le header reste ancré en haut ; seul l'espace du
          // Expanded se réduit, ce qui pousse le bloc action au-dessus du clavier.
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                // HEADER — inchangé
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'MY',
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
                                'COLLECTION',
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
                                'OF VINYL',
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
                          ),
                        ),
                      ),
                      const AppLogo(size: 68),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _LanguageToggle(
                            isFrench: _isFrench,
                            onChanged: (value) =>
                                setState(() => _isFrench = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // NOUVEAU : titre + sous-titre + carrousel masqués (fondu)
                // pendant que le clavier est ouvert.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Align(
                            alignment: const Alignment(0, -0.3),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    _s(
                                      'Connect your Discogs account',
                                      'Connecter votre compte Discogs',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    _s(
                                      "Follow the 4 steps below to get started in just a few minutes.",
                                      "Suivez les 4 étapes ci-dessous pour commencer en quelques minutes.",
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.60),
                                      fontSize: 13.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Seul le carrousel se masque quand le
                                // clavier est ouvert — le titre et le
                                // sous-titre au-dessus restent visibles
                                // en permanence.
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: keyboardVisible
                                      ? const SizedBox.shrink(key: ValueKey('empty'))
                                      : OnboardingCarousel(
                                          key: const ValueKey('carousel'),
                                          steps: _steps,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // BLOC ACTION — inchangé, remonte tout seul grâce à l'AnimatedPadding
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _openDiscogsSettings,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 15),
                              label: Text(
                                _s('Create my Discogs key', 'Créer ma clé Discogs'),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controller,
                              enabled: !_isLoading,
                              obscureText: true,
                              autocorrect: false,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: _s('Paste your Discogs key', 'Coller votre clé Discogs'),
                                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: (_errorMessage != null || _successMessage != null)
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _errorMessage ?? _successMessage!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _errorMessage != null
                                              ? const Color(0xFFFF8A8A)
                                              : const Color(0xFF8AFFA8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _testConnection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : Text(
                                      _s('Test connection', 'Tester la connexion'),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

/// Petit toggle segmenté EN / FR, uniquement pour cet écran de configuration.
/// Un seul tap n'importe où sur le composant bascule sur l'autre langue,
/// pas besoin de cibler précisément "EN" ou "FR".
class _LanguageToggle extends StatelessWidget {
  final bool isFrench;
  final ValueChanged<bool> onChanged;

  const _LanguageToggle({required this.isFrench, required this.onChanged});

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
            _option('EN', !isFrench),
            _option('FR', isFrench),
          ],
        ),
      ),
    );
  }

  Widget _option(String label, bool active) {
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