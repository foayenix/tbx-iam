import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/theme/app_theme.dart';

/// Root app widget
class IAmApp extends ConsumerWidget {
  const IAmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'I AM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Dark-first MVP
      routerConfig: router,
    );
  }
}
