import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await bootstrapFirebase().timeout(const Duration(seconds: 12));
  } catch (e, st) {
    debugPrint('Firebase bootstrap timed out or failed: $e\n$st');
  }
  runApp(const ProviderScope(child: FamilyMessengerApp()));
}

class FamilyMessengerApp extends ConsumerWidget {
  const FamilyMessengerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isFirebaseBootstrapOk) {
      return MaterialApp(
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: _BootstrapErrorScreen(error: firebaseBootstrapError),
        debugShowCheckedModeBanner: false,
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Семья',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Не удалось подключиться к Firebase',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'Неизвестная ошибка',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Запустите эмуляторы: npx firebase emulators:start',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
