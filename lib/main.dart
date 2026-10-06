import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'viewmodels/cv_viewmodel.dart';
import 'viewmodels/ai_agent_viewmodel.dart';
import 'theme/app_theme.dart';
import 'views/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    // If already initialized or platform-specific
    try {
      if (Firebase.apps.isNotEmpty) {
        firebaseReady = true;
      }
    } catch (_) {}
    debugPrint('Firebase initialization status: $e');
  }

  runApp(CvBuilderApp(firebaseReady: firebaseReady));
}

class CvBuilderApp extends StatelessWidget {
  final bool firebaseReady;

  const CvBuilderApp({super.key, this.firebaseReady = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CvViewModel()),
        ChangeNotifierProvider(create: (_) => AiAgentViewModel()),
      ],
      child: MaterialApp(
        title: 'CVBuilder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: AuthGate(firebaseReady: firebaseReady),
      ),
    );
  }
}
