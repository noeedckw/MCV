import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum DiscogsTokenValidationStatus {
  valid,
  empty,
  unauthorized,
  forbidden,
  network,
  unknown,
}

class DiscogsTokenValidationResult {
  final DiscogsTokenValidationStatus status;
  final String message;
  final String? username;
  final int? statusCode;

  const DiscogsTokenValidationResult(
    this.status,
    this.message, {
    this.username,
    this.statusCode,
  });

  bool get isValid => status == DiscogsTokenValidationStatus.valid;
}

class DiscogsAuthService {
  static const _identityUrl = 'https://api.discogs.com/oauth/identity';

  Future<DiscogsTokenValidationResult> validateToken(String token) async {
    final trimmed = token.trim();

    if (trimmed.isEmpty) {
      return const DiscogsTokenValidationResult(
        DiscogsTokenValidationStatus.empty,
        'Veuillez saisir votre clé Discogs.',
      );
    }

    try {
      final response = await http.get(
        Uri.parse(_identityUrl),
        headers: {
          'Authorization': 'Discogs token=$trimmed',
          'User-Agent': 'VinylCollectionApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return DiscogsTokenValidationResult(
            DiscogsTokenValidationStatus.valid,
            'Connexion réussie.',
            username: data['username'] as String?,
            statusCode: response.statusCode,
          );
        case 401:
          return DiscogsTokenValidationResult(
            DiscogsTokenValidationStatus.unauthorized,
            'Cette clé Discogs est invalide. Vérifiez votre clé ou créez-en une nouvelle.',
            statusCode: response.statusCode,
          );
        case 403:
          return DiscogsTokenValidationResult(
            DiscogsTokenValidationStatus.forbidden,
            'Accès refusé par Discogs. Vérifiez les permissions de votre clé.',
            statusCode: response.statusCode,
          );
        default:
          return DiscogsTokenValidationResult(
            DiscogsTokenValidationStatus.unknown,
            'Erreur Discogs (code ${response.statusCode}). Réessayez plus tard.',
            statusCode: response.statusCode,
          );
      }
    } on TimeoutException {
      return const DiscogsTokenValidationResult(
        DiscogsTokenValidationStatus.network,
        'Le serveur Discogs met trop de temps à répondre. Vérifiez votre connexion.',
      );
    } catch (e) {
      return DiscogsTokenValidationResult(
        DiscogsTokenValidationStatus.network,
        'Impossible de contacter Discogs. Vérifiez votre connexion internet.',
      );
    }
  }
}