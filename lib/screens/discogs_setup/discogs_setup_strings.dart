import '../../services/discogs_auth_service.dart';

/// Centralise tous les textes (EN/FR) de l'écran de configuration Discogs.
///
/// Évite de disperser des appels `_s(en, fr)` dans tout le widget : chaque
/// écran ou sous-widget qui a besoin d'un texte reçoit une instance de
/// cette classe et lit directement le getter correspondant.
class DiscogsSetupStrings {
  final bool isFrench;

  const DiscogsSetupStrings({required this.isFrench});

  String _s(String en, String fr) => isFrench ? fr : en;

  // Header
  String get headerLine1 => 'MY';
  String get headerLine2 => 'COLLECTION';
  String get headerLine3 => 'OF VINYL';

  // Titre / sous-titre
  String get title => _s(
        'Connect your Discogs account',
        'Connecter votre compte Discogs',
      );

  String get subtitle => _s(
        'Follow the 4 steps below to get started in just a few minutes.',
        'Suivez les 4 étapes ci-dessous pour commencer en quelques minutes.',
      );

  // Étapes de l'onboarding
  String get step1Title => _s('Create a Discogs account', 'Créez un compte Discogs');
  String get step1Description => _s(
        "Create a free Discogs account if you don't already have one.",
        "Créez gratuitement un compte Discogs si vous n'en avez pas encore un.",
      );

  String get step2Title => _s('Go to Developer Settings', 'Paramètres développeur');
  String get step2Description => _s(
        'Click the "Generate new token" button.',
        'Appuyez sur « Générer un nouveau jeton ».',
      );

  String get step3Title => _s('Copy your token', 'Copiez votre jeton');
  String get step3Description => _s(
        'Copy the value shown after \n"Current token: "and paste it below.',
        "Copiez la valeur affichée après \n« Jeton actuel : » puis collez-la ci-dessous.",
      );

  String get step4Title => _s('Verify & enjoy', 'Vérifiez et profitez');
  String get step4Description => _s(
        'Verify your token and start using the app.',
        'Vérifiez votre jeton puis profitez de l\u2019application.',
      );

  // Bloc action
  String get openSettingsButton => _s('Create my Discogs key', 'Créer ma clé Discogs');
  String get tokenFieldLabel => _s('Paste your Discogs key', 'Coller votre clé Discogs');
  String get testConnectionButton => _s('Test connection', 'Tester la connexion');

  String get couldNotOpenBrowser => _s(
        "Couldn't open the browser.",
        "Impossible d'ouvrir le navigateur.",
      );

  String connectedAs(String username) => _s(
        'Connected as $username.',
        'Connecté en tant que $username.',
      );

  String get connectionSuccessful =>
      _s('Connection successful.', 'Connexion réussie.');

  /// Traduit le résultat de validation Discogs dans la langue active,
  /// à partir de `result.status` (enum) plutôt que de `result.message`
  /// (toujours en français côté service).
  String errorMessageFor(DiscogsTokenValidationResult result) {
    switch (result.status) {
      case DiscogsTokenValidationStatus.empty:
        return _s('Please enter your Discogs key.', 'Veuillez saisir votre clé Discogs.');
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
}