import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:smart_plant_care/routes/app_router.dart'; // Ensure this matches your actual router file path and name

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for the current platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Explicitly connect to your Realtime Database instance URL
  FirebaseDatabase.instance.databaseURL = 
      'https://smart-plant-care-fyp-2026-default-rtdb.firebaseio.com';

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Plant Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Pass the static router instance from the AppRouter class
      routerConfig: AppRouter.router, 
      debugShowCheckedModeBanner: false,
    );
  }
}