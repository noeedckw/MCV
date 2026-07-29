import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'services/discogs_api.dart';
import 'services/token_storage_service.dart';
import 'storage/storage_factory.dart';
import 'providers/collection_provider.dart';
import 'providers/explorer_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/nav_bar_visibility_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/discogs_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = createStorageService();
  await storage.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(AppRoot(storage: storage));
}

/// Porte d'entrée : vérifie qu'une clé Discogs existe avant de construire
/// MyApp (et donc DiscogsApi + tous les providers qui en dépendent).
/// Remplace l'ancien chargement direct via dotenv dans main().
class AppRoot extends StatefulWidget {
  final dynamic storage;
  const AppRoot({super.key, required this.storage});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final TokenStorageService _tokenStorageService = SecureTokenStorageService();

  bool _isLoading = true;
  DiscogsApi? _discogsApi;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final hasToken = await _tokenStorageService.hasToken();
    DiscogsApi? api;
    if (hasToken) {
      api = await DiscogsApi.fromStorage(_tokenStorageService);
    }
    if (!mounted) return;
    setState(() {
      _discogsApi = api;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_discogsApi == null) {
      return MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: const Color.fromARGB(255, 24, 23, 25),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: DiscogsSetupScreen(
          tokenStorageService: _tokenStorageService,
          onConfigured: () async {
            final api = await DiscogsApi.fromStorage(_tokenStorageService);
            setState(() => _discogsApi = api);
          },
        ),
      );
    }

    return MyApp(storage: widget.storage, discogsApi: _discogsApi!);
  }
}

class MyApp extends StatelessWidget {
  final storage;
  final DiscogsApi discogsApi;
  const MyApp({super.key, required this.storage, required this.discogsApi});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CollectionProvider(storage)),

        ChangeNotifierProxyProvider<CollectionProvider, ExplorerProvider>(
          create: (ctx) => ExplorerProvider(
            discogsApi,
            storage,
            ctx.read<CollectionProvider>(),
          ),
          update: (ctx, collectionProvider, previous) =>
              previous ??
              ExplorerProvider(discogsApi, storage, collectionProvider),
        ),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => NavBarVisibilityProvider()),
      ],
      child: MaterialApp(
        title: 'MCV',
        theme: ThemeData(
          colorSchemeSeed: const Color.fromARGB(255, 24, 23, 25),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}