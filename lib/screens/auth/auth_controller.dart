// lib/screens/auth/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _loadCurrentUser(); // load user when app starts
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  String? _error;
  UserModel? _user;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;

  // Load existing Firebase user on app start / restart
  Future<void> _loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _user = UserModel(
        id: 0,
        name: firebaseUser.displayName ??
            firebaseUser.email ??
            'Delivery Partner',
        email: firebaseUser.email ?? '',
        phone: '',
        profilePic: firebaseUser.photoURL ?? '',
      );
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = cred.user;

      if (firebaseUser != null) {
        _user = UserModel(
          id: 0,
          name: firebaseUser.displayName ??
              firebaseUser.email ??
              'Delivery Partner',
          email: firebaseUser.email ?? '',
          phone: '',
          profilePic: firebaseUser.photoURL ?? '',
        );
      }

      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _loading = false;
      _error = e.message ?? 'Firebase auth error';
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // sign up with name
  Future<bool> signup(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = cred.user;

      if (firebaseUser != null) {
        // set Firebase Auth displayName
        await firebaseUser.updateDisplayName(name);
        await firebaseUser.reload();
        final refreshed = _auth.currentUser;

        _user = UserModel(
          id: 0,
          name: refreshed?.displayName ?? name,
          email: refreshed?.email ?? email,
          phone: '',
          profilePic: refreshed?.photoURL ?? '',
        );
      }

      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _loading = false;
      _error = e.message ?? 'Firebase auth error';
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
