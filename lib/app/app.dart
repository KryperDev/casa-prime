import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/theme_service.dart';
import 'routes.dart';

class CasaPrimeApp extends StatefulWidget {
  const CasaPrimeApp({super.key});

  @override
  State<CasaPrimeApp> createState() => _CasaPrimeAppState();
}

class _CasaPrimeAppState extends State<CasaPrimeApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    // Sincroniza com o Firestore depois que o app carrega
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ThemeService().syncFromFirestore(_themeController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Casa Prime',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.mode,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => ThemeControllerProvider(
            controller: _themeController,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// InheritedWidget para expor o ThemeController pela árvore.
class ThemeControllerProvider extends InheritedWidget {
  final ThemeController controller;

  const ThemeControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(w != null, 'ThemeControllerProvider não encontrado no contexto.');
    return w!.controller;
  }

  @override
  bool updateShouldNotify(ThemeControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
