import 'package:flutter/material.dart';
import 'package:smart_plant_care/constants/app_theme.dart';
import 'package:smart_plant_care/routes/app_router.dart';

class SmartPlantCareApp extends StatelessWidget {
  const SmartPlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Plant Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}