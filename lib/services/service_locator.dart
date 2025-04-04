import 'package:get_it/get_it.dart';
import '../providers/app_provider.dart';
import 'network_tracker_service.dart';
import 'firebase_notification_service.dart';
import 'version_service.dart';

/// A simple service locator to access services throughout the app
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  
  ServiceLocator._internal();
  
  // Service instances
  late NetworkTrackerService networkTracker;
  late VersionService versionService;
  
  // Initialize services
  void initialize(AppProvider appProvider) {
    networkTracker = NetworkTrackerService(appProvider);
    versionService = VersionService();
    
    // Initialize GetIt service locator
    setupServiceLocator(appProvider);
  }
}

// Global instance for easy access
final serviceLocator = ServiceLocator();

final GetIt serviceLocatorGetIt = GetIt.instance;

void setupServiceLocator([AppProvider? appProvider]) {
  // Register services as singletons
  if (appProvider != null) {
    serviceLocatorGetIt.registerLazySingleton<NetworkTrackerService>(() => NetworkTrackerService(appProvider));
  }
  
  serviceLocatorGetIt.registerLazySingleton<FirebaseNotificationService>(() => FirebaseNotificationService());
  serviceLocatorGetIt.registerLazySingleton<VersionService>(() => VersionService());
} 