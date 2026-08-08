import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/discogs_auth_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/discogs_setup/onboarding_carousel.dart';
import 'discogs_setup/discogs_onboarding_steps.dart';
import 'discogs_setup/discogs_setup_strings.dart';
import '../widgets/discogs_setup/discogs_setup_header.dart';
import '../widgets/discogs_setup/discogs_token_form.dart';

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
  bool _otherLangPrecached = false;

  DiscogsSetupStrings get _strings => DiscogsSetupStrings(isFrench: _isFrench);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_otherLangPrecached) {
      _otherLangPrecached = true;
      _precacheOtherLanguageImages();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _precacheOtherLanguageImages() async {
    for (final path in DiscogsOnboardingImages.otherLanguage(_isFrench)) {
      await precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  Future<void> _openDiscogsSettings() async {
    final uri = Uri.parse('https://www.discogs.com/settings/developers');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      setState(() => _errorMessage = _strings.couldNotOpenBrowser);
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
            ? _strings.connectedAs(result.username!)
            : _strings.connectionSuccessful;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) widget.onConfigured();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = _strings.errorMessageFor(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
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
            // Compense manuellement le clavier (resizeToAvoidBottomInset est
            // à false) : le header reste ancré en haut, seul l'espace du
            // Expanded se réduit, ce qui pousse le bloc action au-dessus du
            // clavier.
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Column(
                children: [
                  DiscogsSetupHeader(
                    strings: strings,
                    isFrench: _isFrench,
                    onLanguageChanged: (value) => setState(() => _isFrench = value),
                  ),
                  Expanded(
                    child: _OnboardingBody(
                      strings: strings,
                      keyboardVisible: keyboardVisible,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: DiscogsTokenForm(
                      strings: strings,
                      controller: _controller,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      successMessage: _successMessage,
                      onOpenSettings: _openDiscogsSettings,
                      onTestConnection: _testConnection,
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

/// Titre + sous-titre + carrousel des étapes. Seul le carrousel se masque
/// quand le clavier est ouvert ; le titre et le sous-titre au-dessus
/// restent visibles en permanence.
class _OnboardingBody extends StatelessWidget {
  final DiscogsSetupStrings strings;
  final bool keyboardVisible;

  const _OnboardingBody({required this.strings, required this.keyboardVisible});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      strings.title,
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
                      strings.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: keyboardVisible
                        ? const SizedBox.shrink(key: ValueKey('empty'))
                        : OnboardingCarousel(
                            key: const ValueKey('carousel'),
                            steps: buildDiscogsOnboardingSteps(strings),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}