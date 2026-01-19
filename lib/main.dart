// lib/main.dart - OPTIMIZED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Controllers ---
import 'package:deliveryui/screens/auth/auth_controller.dart';
import 'package:deliveryui/screens/auth/login_page.dart';
import 'package:deliveryui/screens/deliveries/deliveries_controller.dart';
import 'package:deliveryui/screens/earnings/earnings_controller.dart';
import 'package:deliveryui/screens/home/home_controller.dart';
import 'package:deliveryui/screens/nav/bottom_nav.dart';
import 'package:deliveryui/screens/nav/nav_controller.dart';
import 'package:deliveryui/screens/profile/profile_controller.dart';
import 'package:deliveryui/screens/splash/splash_screen.dart';
import 'package:deliveryui/screens/kyc/kyc_page.dart';
import 'core/locale_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Start app immediately, load preferences asynchronously
  runApp(const DeliveryBoyApp());
}

class DeliveryBoyApp extends StatelessWidget {
  const DeliveryBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Initialize providers lazily - only when needed
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
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
          create: (ctx) => DeliveriesController(authController: ctx.read<AuthController>()),
          update: (ctx, auth, previous) =>
          previous ?? DeliveriesController(authController: auth),
        ),

        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => EarningsController()),
      ],
      child: Consumer2<LocaleProvider, SettingsProvider>(
        builder: (context, localeProvider, settingsProvider, child) {
          return MaterialApp(
            title: 'Tiffinity Delivery Partner',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            themeMode: settingsProvider.themeMode,

            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.green,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.green,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF1E1E1E),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),

            // ✅ Load async data in splash screen
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
