import 'package:flutter/material.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/theme_controller.dart';
import 'package:pfb/core/theme/theme_scope.dart';
import 'package:pfb/features/splash/presentation/screens/splash_screen.dart';
import 'package:pfb/services/admin_preview_controller.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/notification_navigation_service.dart';

class IftApp extends StatefulWidget {
  const IftApp({super.key});

  @override
  State<IftApp> createState() => _IftAppState();
}

class _IftAppState extends State<IftApp> {
  final ThemeController _themeController = ThemeController();
  final AdminPreviewController _adminPreviewController =
      AdminPreviewController();

  @override
  void dispose() {
    _themeController.dispose();
    _adminPreviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _themeController,
          _adminPreviewController,
        ]),
        builder: (context, _) {
          return AdminPreviewScope(
            controller: _adminPreviewController,
            child: MaterialApp(
              title: "Sakash",
              debugShowCheckedModeBanner: false,
              navigatorKey: NotificationNavigationService.instance.navigatorKey,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _themeController.themeMode,
              onGenerateRoute: AppRouter.onGenerateRoute,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
