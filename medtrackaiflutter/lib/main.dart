import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

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
import 'data/repositories/symptom_repository_impl.dart';
import 'widgets/common/global_error_boundary.dart';
import 'services/purchases_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check for production security
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // Initialize Performance Monitoring
  FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);

  // Set Production Version Metadata in Crashlytics
  await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.0+1');

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Peripheral Services in Parallel
  final results = await Future.wait([
    NotificationService.init(),
    EncryptionService.init(),
    SharedPreferences.getInstance(),
    PurchasesService.init(),
  ]);

  final prefs = results[2] as SharedPreferences;
  final localDataSource = LocalDataSource(prefs);
  final firestoreDataSource = FirestoreDataSource();
  final storageService = StorageService();

  final medRepo = MedicationRepositoryImpl(
      localDataSource, firestoreDataSource, storageService);
  final userRepo = UserRepositoryImpl(localDataSource, firestoreDataSource);
  final symptomRepo = SymptomRepositoryImpl(localDataSource);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    GlobalErrorBoundary(
      child: ChangeNotifierProvider(
        create: (_) => AppState(
          medRepo: medRepo,
          userRepo: userRepo,
          symptomRepo: symptomRepo,
          prefs: prefs,
        )..loadFromStorage(),
        builder: (context, child) {
          final state = context.read<AppState>();
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: state.auth),
              ChangeNotifierProvider.value(value: state.med),
              ChangeNotifierProvider.value(value: state.wellness),
              ChangeNotifierProvider.value(value: state.social),
              ChangeNotifierProvider.value(value: state.health),
            ],
            child: const MedAIApp(),
          );
        },
      ),
    ),
  );
}

class MedAIApp extends StatelessWidget {
  const MedAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final amoled = context
        .select<AppState, bool>((state) => state.profile?.amoledMode ?? false);
    final accentHex = context
        .select<AppState, String?>((state) => state.profile?.accentColor);

    final lightTheme = AppTheme.light(accentHex: accentHex);
    final darkTheme = AppTheme.dark(accentHex: accentHex, isAmoled: amoled);
    final language =
        context.select<AppState, String>((state) => state.language);
    final isDarkMode =
        context.select<AppState, bool>((state) => state.darkMode);

    return MaterialApp(
      title: 'MedAI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      builder: (context, child) {
        final L = context.L;
        return Container(
          color: L.meshBg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child,
            ),
          ),
        );
      },
      scrollBehavior: const _AppScrollBehavior(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
      },
      home: _RootRouter(),
    );
  }
}

class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _RootRouter extends StatefulWidget {
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  String? _lastKnownUid;

  @override
  Widget build(BuildContext context) {
    final phase = context.select<AppState, AppPhase>((state) => state.phase);

    // Listen to Firebase auth state to reload data ONLY on actual UID changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final currentUid = authSnap.data?.uid;

        // Only reload from storage when the UID genuinely changes (sign-in / sign-out)
        // Do NOT reload every rebuild — this would race with completeOnboarding's saveProfile
        if (currentUid != _lastKnownUid) {
          _lastKnownUid = currentUid;
          // Only reload if we are already in app phase (i.e. not during onboarding setup)
          if (phase == AppPhase.app) {
            final appState = context.read<AppState>();
            Future.microtask(() => appState.loadFromStorage());
          }
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
        Image.asset('assets/images/app_logo.png', width: 120, height: 120)
            .animate()
            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
        const SizedBox(height: 24),
        Text('MedAI',
                style: AppTypography.displayLarge.copyWith(
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
