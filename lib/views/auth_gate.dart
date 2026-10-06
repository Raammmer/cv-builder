import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../viewmodels/cv_viewmodel.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  final bool firebaseReady;

  const AuthGate({super.key, required this.firebaseReady});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _homeShownBefore = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) return const HomeScreen();

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          StorageService.userId = null;
          return const LoginScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          StorageService.userId = null;
          return const LoginScreen();
        }

        if (StorageService.userId != user.uid) {
          StorageService.userId = user.uid;
          StorageService.syncUserProfile(user);

          if (_homeShownBefore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.read<CvViewModel>().init();
            });
          }
        }
        _homeShownBefore = true;
        return HomeScreen(key: ValueKey(user.uid));
      },
    );
  }
}
