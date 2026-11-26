import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/kos_repository.dart';
import 'screens/about_screen.dart';
import 'screens/kos_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_kos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupResult = await initializeSupabase(
    initializer: (url, anonKey) async {
      await Supabase.initialize(url: url, publishableKey: anonKey);
    },
  );

  runApp(
    MyApp(
      startupResult: startupResult,
      supabaseClient: startupResult.isReady ? Supabase.instance.client : null,
    ),
  );
}

typedef SupabaseInitializer = Future<void> Function(String url, String anonKey);

Future<AppStartupResult> initializeSupabase({
  required SupabaseInitializer initializer,
  String? url,
  String? anonKey,
}) async {
  late final SupabaseConfig config;
  try {
    config = SupabaseConfig.fromEnvironment(
      urlOverride: url,
      anonKeyOverride: anonKey,
    );
  } on SupabaseConfigException catch (error) {
    return AppStartupResult.failure(error.message);
  }

  try {
    await initializer(config.url, config.anonKey);
    return const AppStartupResult.success();
  } on Exception {
    return const AppStartupResult.failure(
      'Supabase gagal diinisialisasi. Periksa konfigurasi dan koneksi, '
      'lalu jalankan ulang aplikasi.',
    );
  }
}

class AppStartupResult {
  const AppStartupResult.success() : errorMessage = null;

  const AppStartupResult.failure(this.errorMessage);

  final String? errorMessage;

  bool get isReady => errorMessage == null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.startupResult, this.supabaseClient});

  final AppStartupResult startupResult;
  final SupabaseClient? supabaseClient;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final errorMessage = startupResult.errorMessage;
    if (errorMessage != null) {
      return _startupErrorApp(errorMessage);
    }

    final client = supabaseClient;
    if (client == null) {
      return _startupErrorApp(
        'Klien Supabase belum tersedia. Jalankan ulang aplikasi.',
      );
    }

    return Provider<SupabaseClient>.value(
      value: client,
      child: ChangeNotifierProvider(
        create: (_) => AuthProvider(
          AuthRepository(client),
          initiallyAuthenticated: client.auth.currentSession != null,
          sessionChanges: client.auth.onAuthStateChange.map(
            (state) => state.session != null,
          ),
        ),
        child: MaterialApp(
          title: 'KosFinder',
          theme: ThemeData(
            // This is the theme of your application.
            //
            // TRY THIS: Try running your application with "flutter run". You'll see
            // the application has a purple toolbar. Then, without quitting the app,
            // try changing the seedColor in the colorScheme below to Colors.green
            // and then invoke "hot reload" (save your changes or press the "hot
            // reload" button in a Flutter-supported IDE, or press "r" if you used
            // the command line to start the app).
            //
            // Notice that the counter didn't reset back to zero; the application
            // state is not lost during the reload. To reset the state, use hot
            // restart instead.
            //
            // This works for code too, not just values: Most code changes can be
            // tested with just a hot reload.
            colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          ),
          home: KosFinderHome(repository: KosRepository(client)),
        ),
      ),
    );
  }

  MaterialApp _startupErrorApp(String message) {
    return MaterialApp(
      title: 'KosFinder',
      home: SupabaseStartupErrorScreen(message: message),
    );
  }
}

class SupabaseStartupErrorScreen extends StatelessWidget {
  const SupabaseStartupErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KosFinder')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class KosFinderHome extends StatefulWidget {
  const KosFinderHome({super.key, required this.repository});

  final KosRepository repository;

  @override
  State<KosFinderHome> createState() => _KosFinderHomeState();
}

class _KosFinderHomeState extends State<KosFinderHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final visibleIndex =
            _selectedIndex == 2 && !authProvider.isAuthenticated
            ? 0
            : _selectedIndex;
        final showOwnerKos = visibleIndex == 2 && authProvider.isAuthenticated;

        return Scaffold(
          body: IndexedStack(
            index: visibleIndex,
            children: [
              KosListScreen(repository: widget.repository),
              const AboutScreen(),
              showOwnerKos
                  ? OwnerKosScreen(repository: widget.repository)
                  : const _ManagementPlaceholder(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: visibleIndex,
            onDestinationSelected: (index) {
              if (index == 2) {
                _openManagement(context, authProvider);
              } else {
                setState(() => _selectedIndex = index);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Daftar Kos',
              ),
              NavigationDestination(
                icon: Icon(Icons.info_outline),
                label: 'About',
              ),
              NavigationDestination(
                icon: Icon(Icons.manage_accounts_outlined),
                label: 'Kelola',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openManagement(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    if (!authProvider.isAuthenticated) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }

    if (!mounted || !authProvider.isAuthenticated) {
      return;
    }

    setState(() => _selectedIndex = 2);
  }
}

class _ManagementPlaceholder extends StatelessWidget {
  const _ManagementPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengelolaan Kos')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pengelolaan kos akan tersedia pada task berikutnya.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
