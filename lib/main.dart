import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/discogs_api.dart';
import 'storage/storage_factory.dart';
import 'providers/collection_provider.dart';
import 'providers/explorer_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final storage = createStorageService();
  await storage.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final discogsApi = DiscogsApi(dotenv.env['DISCOGS_TOKEN'] ?? '');

  runApp(MyApp(storage: storage, discogsApi: discogsApi));
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
      ],
      child: MaterialApp(
        title: 'Ma Collection Vinyles',
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
