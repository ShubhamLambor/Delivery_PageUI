// lib/main.dart - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// --- KYC Page Import ---
import 'package:deliveryui/screens/kyc/kyc_page.dart';

// --- Locale Provider ---
import 'core/locale_provider.dart';

// --- Settings Provider ---
import 'providers/settings_provider.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // ✅ Initialize SettingsProvider
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(DeliveryBoyApp(
    isLoggedIn: isLoggedIn,
    settingsProvider: settingsProvider,
  ));
}

class DeliveryBoyApp extends StatelessWidget {
  final bool isLoggedIn;
  final SettingsProvider settingsProvider;

  const DeliveryBoyApp({
    super.key,
    required this.isLoggedIn,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Add SettingsProvider at the top
        ChangeNotifierProvider.value(value: settingsProvider),

        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider(create: (_) => AuthController()),

        // HomeController needs AuthController for partnerId
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

        // DeliveriesController needs AuthController
        ChangeNotifierProxyProvider<AuthController, DeliveriesController>(
          create: (ctx) =>
              DeliveriesController(authController: ctx.read<AuthController>()),
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

            // ✅ Dynamic theme mode from SettingsProvider
            themeMode: settingsProvider.themeMode,

            // ✅ Light theme - FIXED: CardTheme → CardThemeData
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
              cardTheme: const CardThemeData( // ✅ Changed to CardThemeData
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),

            // ✅ Dark theme - FIXED: CardTheme → CardThemeData
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
              cardTheme: const CardThemeData( // ✅ Changed to CardThemeData
                color: Color(0xFF1E1E1E),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),

            home: SplashScreen(isLoggedIn: isLoggedIn),
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
