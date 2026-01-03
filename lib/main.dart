// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final User? user = FirebaseAuth.instance.currentUser;
  final bool isLoggedIn = user != null;

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
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => DeliveriesController()),
        ChangeNotifierProvider(create: (_) => EarningsController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Tiffinity Delivery Partner',
            debugShowCheckedModeBanner: false,

            // Bind active locale
            locale: localeProvider.locale,

            theme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
            ),

            home: SplashScreen(isLoggedIn: isLoggedIn),

            routes: {
              '/home': (context) => const BottomNav(),
              '/login': (context) => const LoginPage(),
              '/kyc': (context) => const KYCPage(), // NEW ROUTE ADDED
            },
          );
        },
      ),
    );
  }
}
