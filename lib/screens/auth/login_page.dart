// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../nav/bottom_nav.dart';
import 'auth_controller.dart';
import 'signup_page.dart';
import 'widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: LoginForm(
            loading: controller.loading,
            onSubmit: (email, password) async {
              final success = await controller.login(email, password);
              if (success) {
                if (!context.mounted) return;

                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BottomNav()),
                );
              } else {
                final error = controller.error ?? "Login failed";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            onTapRegister: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupPage()),
              );
            },
          ),
        ),
      ),
    );
  }
}
