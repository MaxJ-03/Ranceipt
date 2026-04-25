import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/receipt_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const RanceiptApp());
}

class RanceiptApp extends StatelessWidget {
  const RanceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceiptProvider(),
      child: MaterialApp(
        title: 'Ranceipt',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.bg,
          fontFamily: 'Roboto',
          colorScheme: const ColorScheme.dark(
            primary: AppColors.aqua,
            secondary: AppColors.primary,
            surface: AppColors.surface,
            error: AppColors.rose,
            onPrimary: AppColors.bg,
            onSecondary: AppColors.text,
            onSurface: AppColors.text,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.text,
            elevation: 0,
            centerTitle: false,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColors.surfaceSoft,
            contentTextStyle: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.surface,
            modalBackgroundColor: AppColors.surface,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceSoft,
            labelStyle: const TextStyle(color: AppColors.muted),
            hintStyle: const TextStyle(color: AppColors.faint),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.aqua),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
