import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/login_screen.dart'; // We will create this next
import 'package:frontend/theme/theme.dart';
import 'package:frontend/state/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://igccgemeztudfkbouzva.supabase.co',
    publishableKey: 'sb_publishable_9cVji3rPVPjFe5zRrGJOIA_0afYwx-Z',
  );

  runApp(const ProviderScope(child: MergeLensApp()));
}

class MergeLensApp extends ConsumerWidget {
  const MergeLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MergeLens Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Auth session failed to load: $error',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      data: (session) =>
          session == null ? const LoginScreen() : const DashboardScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}
