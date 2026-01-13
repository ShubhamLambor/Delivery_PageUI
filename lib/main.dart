// lib/main.dart - SIMPLER VERSION

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

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(DeliveryBoyApp(isLoggedIn: isLoggedIn));
}

class DeliveryBoyApp extends StatelessWidget {
  final bool isLoggedIn;
  const DeliveryBoyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider(create: (_) => AuthController()),

        // HomeController needs AuthController for partnerId
        ChangeNotifierProxyProvider<AuthController, HomeController>(
          create: (_) => HomeController(),
          update: (ctx, auth, previous) {
            // expose a setter in HomeController if needed
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
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Tiffinity Delivery Partner',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            theme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
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
