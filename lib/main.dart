import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'services/discogs_api.dart';
import 'services/token_storage_service.dart';
import 'storage/storage_factory.dart';
import 'storage/grid_columns_store.dart';
import 'providers/collection_provider.dart';
import 'providers/explorer_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/nav_bar_visibility_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/discogs_setup_screen.dart';
import 'widgets/splash_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GridColumnsStore.init();
  final storage = createStorageService();
  await storage.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(AppRoot(storage: storage));
}

/// Racine de l'app : un seul MaterialApp, un seul SplashGate monté une
/// seule fois. Le contenu en dessous (loading / setup Discogs / app
/// principale) change librement selon l'état sans jamais démonter le
/// SplashGate, donc l'animation d'entrée ne se rejoue pas à chaque
/// changement d'état.
class AppRoot extends StatefulWidget {
  final dynamic storage;
  const AppRoot({super.key, required this.storage});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final TokenStorageService _tokenStorageService = SecureTokenStorageService();

  bool _isLoading = true;
  DiscogsApi? _discogsApi; // sert juste à choisir quel écran afficher

  // Créés une seule fois, pour toute la durée de vie de l'app.
  late final CollectionProvider _collectionProvider;
  late final ExplorerProvider _explorerProvider;
  late final ConnectivityProvider _connectivityProvider;
  late final NavBarVisibilityProvider _navBarVisibilityProvider;

  @override
  void initState() {
    super.initState();
    _collectionProvider = CollectionProvider(widget.storage);
    _explorerProvider = ExplorerProvider(widget.storage, _collectionProvider);
    _connectivityProvider = ConnectivityProvider();
    _navBarVisibilityProvider = NavBarVisibilityProvider();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final hasToken = await _tokenStorageService.hasToken();
    DiscogsApi? api;
    if (hasToken) {
      api = await DiscogsApi.fromStorage(_tokenStorageService);
    }
    if (!mounted) return;

    if (api != null) {
      _explorerProvider.configure(api);
    }

    setState(() {
      _discogsApi = api;
      _isLoading = false;
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_discogsApi == null) {
      return DiscogsSetupScreen(
        tokenStorageService: _tokenStorageService,
        onConfigured: () async {
          final api = await DiscogsApi.fromStorage(_tokenStorageService);
          if (!mounted) return;
          _explorerProvider.configure(api);
          setState(() => _discogsApi = api);
        },
      );
    }

    return const MainNavigationScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _collectionProvider),
        ChangeNotifierProvider.value(value: _explorerProvider),
        ChangeNotifierProvider.value(value: _connectivityProvider),
        ChangeNotifierProvider.value(value: _navBarVisibilityProvider),
      ],
      child: MaterialApp(
        title: 'MCV',
        theme: ThemeData(
          colorSchemeSeed: const Color.fromARGB(255, 24, 23, 25),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: SplashGate(
          child: Builder(builder: (context) => _buildContent()),
        ),
      ),
    );
  }
}