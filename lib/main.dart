import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'package:smart_plant_care/routes/app_router.dart';
import 'package:smart_plant_care/services/notification_service.dart';
import 'package:smart_plant_care/services/app_settings.dart';

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase.instance.databaseURL =
      'https://smart-plant-care-fyp-2026-default-rtdb.firebaseio.com';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  await NotificationService.initialize();
  await AppSettings.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Smart Plant Care',
          themeMode: ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF134E39),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFE4EDE6),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFE4EDE6),
              foregroundColor: Color(0xFF134E39),
              elevation: 0,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF65B891),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF101A16),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF101A16),
              foregroundColor: Color(0xFFE2F2E8),
              elevation: 0,
            ),
            cardColor: const Color(0xFF1A2922),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          ),
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}