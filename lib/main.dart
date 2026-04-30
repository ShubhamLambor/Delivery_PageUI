// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Controllers ---
import 'package:TiffinityGo/screens/auth/auth_controller.dart';
import 'package:TiffinityGo/screens/auth/login_page.dart';
import 'package:TiffinityGo/screens/deliveries/deliveries_controller.dart';
import 'package:TiffinityGo/screens/earnings/earnings_controller.dart';
import 'package:TiffinityGo/screens/home/home_controller.dart';
import 'package:TiffinityGo/screens/nav/bottom_nav.dart';
import 'package:TiffinityGo/screens/nav/nav_controller.dart';
import 'package:TiffinityGo/screens/profile/profile_controller.dart';
import 'package:TiffinityGo/screens/splash/splash_screen.dart';
import 'package:TiffinityGo/screens/kyc/kyc_page.dart';
import 'core/locale_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeliveryBoyApp());
}

class DeliveryBoyApp extends StatelessWidget {
  const DeliveryBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, HomeController>(
          create: (_) => HomeController(),
          update: (ctx, auth, previous) {
            previous ??= HomeController();
            final partnerId = auth.getCurrentUserId();
            if (partnerId != null) {
              previous.setPartnerId(partnerId);
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, DeliveriesController>(
          create: (ctx) =>
              DeliveriesController(authController: ctx.read<AuthController>()),
          update: (ctx, auth, previous) =>
          previous ?? DeliveriesController(authController: auth),
        ),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => EarningsController()),
      ],      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Tiffinity Delivery Partner',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,

            // ✅ FORCED LIGHT MODE
            themeMode: ThemeMode.light,
            theme: AppTheme.lightTheme,

            home: const SplashScreen(),
            routes: {
              '/home': (context) => const BottomNav(),
              '/login': (context) => const LoginPage(),
              '/kyc': (context) => const KYCPage(),
            },
          );
        },
      ),
    );
  }
}