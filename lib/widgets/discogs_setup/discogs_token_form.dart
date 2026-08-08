import 'package:flutter/material.dart';

import 'glass_container.dart';
import '../../screens/discogs_setup/discogs_setup_strings.dart';

/// Carte d'action en bas de l'écran : bouton pour ouvrir Discogs, champ de
/// saisie du token, message d'erreur/succès, et bouton de validation.
class DiscogsTokenForm extends StatelessWidget {
  final DiscogsSetupStrings strings;
  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onOpenSettings;
  final VoidCallback onTestConnection;

  const DiscogsTokenForm({
    super.key,
    required this.strings,
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onOpenSettings,
    required this.onTestConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: isLoading ? null : onOpenSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: Text(
                  strings.openSettingsButton,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                enabled: !isLoading,
                obscureText: true,
                autocorrect: false,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: strings.tokenFieldLabel,
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
                child: (errorMessage != null || successMessage != null)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage ?? successMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: errorMessage != null
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
                onPressed: isLoading ? null : onTestConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        strings.testConnectionButton,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}