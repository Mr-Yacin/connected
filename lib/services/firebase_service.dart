import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'error_logging_service.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      ErrorLoggingService.logInitializationSuccess();
    } catch (e, stackTrace) {
      ErrorLoggingService.logConnectionError(
        e,
        stackTrace: stackTrace,
        context: 'Firebase initialization failed',
        screen: 'App Startup',
      );
      rethrow;
    }
  }
}
