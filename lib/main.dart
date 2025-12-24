import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import 'package:eduscan_ai/services/notification_service.dart';

// Screens
import 'package:eduscan_ai/screens/home_screen.dart';
import 'package:eduscan_ai/screens/login_screen.dart';

// Models
import 'package:eduscan_ai/models/class_model.dart';
import 'package:eduscan_ai/models/todo_model.dart';
import 'package:eduscan_ai/models/journal_model.dart';

// Global instance of the notification service for easy access.
final NotificationService notificationService = NotificationService();

Future<void> main() async {
  // This is the entry point of your app.
  try {
    // Ensure that Flutter's binding is initialized before calling native code.
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize all your services in the correct order.
    await Firebase.initializeApp();
    await Hive.initFlutter();
    await notificationService.init();
    await notificationService.requestPermissions();

    // Initialize Google Sign-In
    await GoogleSignIn().signOut(); // Clear any existing sign-in state

    // Register all your Hive data models (TypeAdapters).
    Hive.registerAdapter(ClassModelAdapter());
    Hive.registerAdapter(TodoModelAdapter());
    Hive.registerAdapter(JournalEntryAdapter());

    // Open all the Hive boxes you will use in your app.
    await Hive.openBox<ClassModel>('classes');
    await Hive.openBox<TodoModel>('todos');
    await Hive.openBox<JournalEntry>('journal_entries');

    // Once everything is initialized, run the app.
    runApp(const EduScanApp());
  } catch (e) {
    // If any error occurs during initialization, print it to the debug console.
    debugPrint("Error during app initialization: $e");
  }
}

class EduScanApp extends StatefulWidget {
  const EduScanApp({super.key});

  @override
  State<EduScanApp> createState() => _EduScanAppState();
}

class _EduScanAppState extends State<EduScanApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add this widget as an observer to listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Start ongoing lecture monitoring when app starts (respecting user preference)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  @override
  void dispose() {
    // Remove observer and stop monitoring when app is disposed
    WidgetsBinding.instance.removeObserver(this);
    notificationService.stopOngoingLectureMonitoring();
    super.dispose();
  }

  // Initialize notifications based on user preference
  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('ongoing_lecture_notifications') ?? true;

      if (notificationsEnabled) {
        await notificationService.startOngoingLectureMonitoring();
        debugPrint('Ongoing lecture notifications started');
      } else {
        debugPrint('Ongoing lecture notifications disabled by user');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check if notifications should be running
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        // App went to background - continue notifications
        debugPrint(
          'App paused - continuing lecture notifications in background',
        );
        break;
      case AppLifecycleState.detached:
        // App is detached - stop monitoring to save resources
        notificationService.stopOngoingLectureMonitoring();
        debugPrint('App detached - stopping lecture notifications');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App is inactive or hidden - no action needed
        break;
    }
  }

  // Handle app resuming from background
  Future<void> _handleAppResumed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('ongoing_lecture_notifications') ?? true;

      if (notificationsEnabled) {
        await notificationService.startOngoingLectureMonitoring();
        debugPrint('App resumed - restarting lecture notifications');
      } else {
        debugPrint('App resumed - notifications disabled by user');
      }
    } catch (e) {
      debugPrint('Error handling app resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduScan AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.grey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
      // The AuthGate will decide whether to show the HomeScreen or LoginScreen.
      home: const AuthGate(),
    );
  }
}

/// A widget that listens to the authentication state and shows the correct screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If we are still waiting for the auth state, show a loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If the user is logged in, show the HomeScreen.
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Otherwise, the user is logged out, so show the LoginScreen.
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
