import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_constants.dart';
import 'providers/app_provider.dart';
import 'services/network_tracker_service.dart';
import 'services/service_locator.dart';
import 'services/version_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/donor_search_screen.dart';
import 'screens/blood_request_screen.dart';
import 'screens/blood_requests_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/blood_banks_screen.dart';
import 'screens/donation_history_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/data_usage_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/health_tips_screen.dart';
import 'screens/health_questionnaire_screen.dart';
import 'screens/medical_conditions_screen.dart';
import 'screens/donation_tracking_screen.dart';
import 'utils/localization/app_localization.dart';
import 'firebase/firebase_service.dart';
import 'services/firebase_notification_service.dart';
import 'widgets/blood_request_notification_dialog.dart';
import 'utils/app_updater.dart';

// Create a separate function for initialization
Future<void> _initializeApp() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  try {
    await FirebaseService.initialize();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Continue execution despite the error
  }

  // Load environment variables but don't halt execution if file is missing
  try {
    await dotenv.load(fileName: "assets/config/.env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    // Continue execution despite the error
  }
  
  // Initialize app version service
  try {
    await versionService.initialize();
    // Set AppUpdater version for backward compatibility
    AppUpdater.currentVersion = versionService.appVersion;
    debugPrint('VersionService initialized with version: ${versionService.appVersion}');
  } catch (e) {
    debugPrint('Failed to initialize VersionService: $e');
    // Continue execution despite the error
  }
}

void main() async {
  // Initialize app components
  await _initializeApp();

  // Create the app provider
  final appProvider = AppProvider();

  // Initialize services
  serviceLocator.initialize(appProvider);

  // Initialize notification service - moved to widget's initState
  // to ensure we have context available

  runApp(
    ChangeNotifierProvider.value(value: appProvider, child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();

  @override
  void initState() {
    super.initState();
    // Register as an observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    debugPrint('\n\n🔄🔄🔄 BLOODLINE APP STARTING 🔄🔄🔄');
    
    // Initialize notification service after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔄 [AppLifecycle] UI rendered, initializing services...');
      _initializeNotifications().then((_) {
        // We will NOT sync notifications here on app startup anymore
        // Instead, we'll rely on the auth state change listener and refreshUserData method
        // to handle notification syncing after user authentication
        debugPrint('🔄 [AppLifecycle] First UI frame complete, notification services initialized');
        debugPrint('🔄 [AppLifecycle] Waiting for auth state to determine if sync is needed');
      });
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('\n🔄 [AppLifecycle] App state changed to: $state');
    
    // When app is resumed from background or inactive state, sync notifications
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 [AppLifecycle] App resumed from background, triggering notification sync');
      _syncNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    debugPrint('🔄 [Notifications] Initializing notification services');
    await _notificationService.initialize(context);
    debugPrint('🔄 [Notifications] Notification services initialized successfully');
  }

  // Sync notifications when app is resumed
  Future<void> _syncNotifications({bool isInitialSync = false}) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Only refresh if user is logged in
      if (appProvider.isLoggedIn) {
        // Print debug information
        if (isInitialSync) {
          debugPrint('\n🔄🔄🔄 NOTIFICATION INITIAL SYNC STARTED 🔄🔄🔄');
        } else {
          debugPrint('\n🔄🔄🔄 NOTIFICATION RESUME SYNC STARTED 🔄🔄🔄');
        }
        
        debugPrint('🔄 [NotificationSync] Step 1/3: Refreshing notifications from Firestore...');
        // Refresh notifications from Firestore
        await appProvider.refreshNotifications();
        
        debugPrint('🔄 [NotificationSync] Step 2/3: Checking notification settings...');
        // Check notification settings
        await appProvider.checkNotificationSettings();
        
        debugPrint('🔄 [NotificationSync] Step 3/3: Ensuring device token is up to date...');
        // Ensure token is saved (in case it changed)
        await _notificationService.saveDeviceToken();
        
        if (isInitialSync) {
          debugPrint('✅✅✅ NOTIFICATION INITIAL SYNC COMPLETED ✅✅✅\n');
        } else {
          debugPrint('✅✅✅ NOTIFICATION RESUME SYNC COMPLETED ✅✅✅\n');
        }
      } else {
        debugPrint('⚠️ [NotificationSync] Notification sync skipped: User not logged in');
      }
    } catch (e) {
      debugPrint('❌❌❌ ERROR SYNCING NOTIFICATIONS: $e ❌❌❌');
      // Handle errors silently to avoid app crashes
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    // Determine if the current language requires right-to-left layout
    final isRtl =
        appProvider.locale.languageCode == 'ar' ||
        appProvider.locale.languageCode == 'ur';

    return MaterialApp(
      title: 'BloodLine',
      debugShowCheckedModeBanner: false,

      // Localization support
      locale: appProvider.locale,
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
        Locale('fr', 'FR'), // French
        Locale('ar', 'SA'), // Arabic
        Locale('ur', 'PK'), // Urdu
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Set text direction based on language
      builder: (context, child) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AnimatedTheme(
            duration: const Duration(milliseconds: 300),
            data: Theme.of(context),
            child: child!,
          ),
        );
      },

      theme: AppConstants.lightTheme,
      darkTheme: AppConstants.darkTheme,
      themeMode: appProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/donor_search': (context) => const DonorSearchScreen(),
        '/blood_request': (context) => const BloodRequestScreen(),
        '/blood_requests_list': (context) => const BloodRequestsListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/notification_settings':
            (context) => const NotificationSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/blood_banks': (context) => const BloodBanksScreen(),
        '/donation_history': (context) => const DonationHistoryScreen(),
        '/donation_tracking': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final initialIndex = args?['initialIndex'] as int?;
          final subTabIndex = args?['subTabIndex'] as int?;
          return DonationTrackingScreen(
            initialIndex: initialIndex,
            subTabIndex: subTabIndex,
          );
        },
        '/about_us': (context) => const AboutUsScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/terms_conditions': (context) => const TermsConditionsScreen(),
        '/data_usage': (context) => const DataUsageScreen(),
        '/emergency_contacts': (context) => const EmergencyContactsScreen(),
        '/health_tips': (context) => const HealthTipsScreen(),
        '/health-questionnaire': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final isPostSignup =
              args != null ? args['isPostSignup'] ?? false : false;
          return HealthQuestionnaireScreen(isPostSignup: isPostSignup);
        },
        '/medical-conditions': (context) => const MedicalConditionsScreen(),
        '/blood_request_notification': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return BloodRequestNotificationDialog(
            requestId: args?['requestId'] ?? '',
            requesterId: args?['requesterId'] ?? '',
            requesterName: args?['requesterName'] ?? '',
            requesterPhone: args?['requesterPhone'] ?? '',
            bloodType: args?['bloodType'] ?? '',
            location: args?['location'] ?? '',
            city: args?['city'] ?? '',
            urgency: args?['urgency'] ?? 'High',
            notes: args?['notes'] ?? '',
            requestDate: args?['requestDate'] ?? DateTime.now().toString(),
          );
        },
      },
    );
  }
}
