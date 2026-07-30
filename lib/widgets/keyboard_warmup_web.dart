import 'dart:js_interop';

/// Appelle window.mcvWarmupKeyboard() défini dans index.html.
/// Doit être appelé UNIQUEMENT depuis un vrai geste utilisateur (tap),
/// sinon iOS refuse d'ouvrir le clavier.
@JS('mcvWarmupKeyboard')
external void _jsWarmupKeyboard();

void warmupKeyboard() {
  _jsWarmupKeyboard();
}
