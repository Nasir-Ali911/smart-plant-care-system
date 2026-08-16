import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_plant_care/screens/splash/splash_screen.dart';
import 'package:smart_plant_care/screens/login/login_screen.dart';
import 'package:smart_plant_care/screens/login/register_screen.dart';
import 'package:smart_plant_care/screens/login/forgot_password_screen.dart';
import 'package:smart_plant_care/screens/dashboard/dashboard_screen.dart';
import 'package:smart_plant_care/screens/plant_details/plant_details_screen.dart';
import 'package:smart_plant_care/screens/profile/profile_screen.dart';
import 'package:smart_plant_care/models/plant_model.dart'; // Added model import

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/plant-details',
        name: 'plant-details',
        builder: (context, state) {
          // Safely extract the PlantModel from extra, with a safe fallback
          final plant = state.extra as PlantModel? ??
              PlantModel(
                id: '',
                name: 'Default Plant',
                species: '',
                moisture: '0%',
                temperature: '0°C',
                lastUpdated: 'Just now',
                addedDate: DateTime.now(),
                location: '',
                status: 'Unknown',
              );
          return PlantDetailsScreen(plant: plant);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}