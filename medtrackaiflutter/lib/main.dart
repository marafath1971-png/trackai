import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/app_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'services/notification_service.dart';
import 'services/encryption_service.dart';
import 'services/storage_service.dart';
import 'data/datasources/local_prefs_datasource.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/repositories/medication_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'widgets/common/global_error_boundary.dart';

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
  final storageService = StorageService();
  final medRepo =
      MedicationRepositoryImpl(localDataSource, firestoreDataSource, storageService);
  final userRepo = UserRepositoryImpl(localDataSource, firestoreDataSource);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    GlobalErrorBoundary(
      child: ChangeNotifierProvider(
        create: (_) =>
            AppState(medRepo: medRepo, userRepo: userRepo)..loadFromStorage(),
        child: const MedAIApp(),
      ),
    ),
  );
}

class MedAIApp extends StatelessWidget {
  const MedAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<AppState, bool>((state) => state.darkMode);
    final accentHex = context.select<AppState, String?>((state) => state.profile?.accentColor);

    final lightTheme = AppTheme.light(accentHex: accentHex);
    final darkTheme = AppTheme.dark(accentHex: accentHex);

    return MaterialApp(
      title: 'Med AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        Locale('fr', ''), // French
        Locale('de', ''), // German
        Locale('zh', ''), // Chinese
        Locale('ja', ''), // Japanese
        Locale('hi', ''), // Hindi
        Locale('bn', ''), // Bengali
        Locale('ar', ''), // Arabic
      ],
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      builder: (context, child) {
        final L = context.L;
        return Container(
          color: L.bg,
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
            // Only force Auth if explicitly in auth phase and NOT in guest app mode
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
        Image.asset('assets/images/app_logo.png', width: 120, height: 120)
            .animate()
            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
        const SizedBox(height: 24),
        Text('Med AI',
            style: GoogleFonts.figtree(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.oText,
                letterSpacing: -1.0))
            .animate()
            .fadeIn(delay: 400.ms, duration: 800.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 48),
        const SizedBox(
            width: 28,
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ))
            .animate()
            .fadeIn(delay: 800.ms)
            .shimmer(duration: 1500.ms, color: Colors.white24),
      ])),
    );
  }
}
