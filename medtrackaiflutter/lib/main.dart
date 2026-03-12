import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/app_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'services/notification_service.dart';
import 'services/encryption_service.dart';
import 'data/datasources/local_prefs_datasource.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/repositories/medication_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await NotificationService.init();
  await EncryptionService.init();

  final prefs = await SharedPreferences.getInstance();
  final localDataSource = LocalDataSource(prefs);
  final firestoreDataSource = FirestoreDataSource();
  final medRepo =
      MedicationRepositoryImpl(localDataSource, firestoreDataSource);
  final userRepo = UserRepositoryImpl(localDataSource, firestoreDataSource);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AppState(medRepo: medRepo, userRepo: userRepo)..loadFromStorage(),
      child: const MedTrackApp(),
    ),
  );
}

class MedTrackApp extends StatelessWidget {
  const MedTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<AppState, bool>((state) => state.darkMode);

    final lightTheme =
        AppTheme.light().copyWith(extensions: [AppThemeColors.light]);
    final darkTheme =
        AppTheme.dark().copyWith(extensions: [AppThemeColors.dark]);

    return MaterialApp(
      title: 'Med AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      builder: (context, child) {
        return Container(
          color: isDark ? const Color(0xFF000000) : const Color(0xFFE5E5E5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child,
            ),
          ),
        );
      },
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
      },
      home: _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final phase = context.select<AppState, AppPhase>((state) => state.phase);

    // Listen to Firebase auth state to reload data on sign-in/out
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // When auth state changes, reload data
        if (authSnap.hasData && phase == AppPhase.app) {
          final appState = context.read<AppState>();
          Future.microtask(() => appState.loadFromStorage());
        }

        switch (phase) {
          case AppPhase.loading:
            return const _SplashLoading();
          case AppPhase.onboarding:
            return const OnboardingScreen();
          case AppPhase.auth:
            return const AuthScreen();
          case AppPhase.app:
            return const AppShell();
        }
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oBg,
      body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/images/app_logo.png', width: 100, height: 100),
        const SizedBox(height: 20),
        Text('Med AI',
            style: GoogleFonts.figtree(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.oText,
                letterSpacing: -0.8)),
        const SizedBox(height: 32),
        const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.oLime)),
      ])),
    );
  }
}
