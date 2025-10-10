import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF2196F3); // Azul
  static const Color secondaryColor = Color(0xFF4CAF50); // Verde
  static const Color accentColor = Color(0xFFFF9800); // Naranja
  static const Color errorColor = Color(0xFFF44336); // Rojo

  // Colores para modo Real (Verde)
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);

  // Colores para modo Simulador (Azul)
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color darkBlue = Color(0xFF0D47A1);

  // Colores modo oscuro MEJORADOS - más claros y vibrantes
  static const Color darkBackgroundPrimary = Color(0xFF1A1A2E); // Azul oscuro más claro
  static const Color darkBackgroundSecondary = Color(0xFF16213E); // Azul profundo
  static const Color darkCardBackground = Color(0xFF0F3460); // Azul medio
  static const Color darkTextPrimary = Color(0xFFEEEEEE); // Texto casi blanco
  static const Color darkTextSecondary = Color(0xFFB8B8D1); // Gris-azul claro

  // Colores de acento para modo oscuro
  static const Color darkAccentBlue = Color(0xFF00D4FF); // Cyan brillante
  static const Color darkAccentPurple = Color(0xFFBB86FC); // Púrpura claro
  static const Color darkAccentGreen = Color(0xFF03DAC6); // Verde azulado

  // Colores neutrales
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerGrey = Color(0xFFBDBDBD);

  // Tema claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      primaryContainer: Color(0xFFE3F2FD),
      secondaryContainer: Color(0xFFE8F5E9),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Cards
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // Botones elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Botones de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // FloatingActionButton
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    ),

    // Iconos
    iconTheme: IconThemeData(
      color: Colors.grey[700],
    ),
  );

  // Tema oscuro MEJORADO - más claro y visualmente atractivo
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkAccentBlue,
    scaffoldBackgroundColor: darkBackgroundPrimary,
    colorScheme: ColorScheme.dark(
      primary: darkAccentBlue,
      secondary: darkAccentGreen,
      tertiary: darkAccentPurple,
      error: Color(0xFFFF6B6B),
      surface: darkCardBackground,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: darkTextPrimary,
      primaryContainer: Color(0xFF1E3A5F),
      secondaryContainer: Color(0xFF1A4D3E),
      background: darkBackgroundPrimary,
      onBackground: darkTextPrimary,
    ),

    // AppBar con gradiente
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackgroundSecondary,
      foregroundColor: darkTextPrimary,
      elevation: 4,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: darkAccentBlue),
    ),

    // Cards con mejor contraste
    cardTheme: CardTheme(
      color: darkCardBackground,
      elevation: 4,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(0xFF1F4788),
          width: 1,
        ),
      ),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // Botones elevados más vibrantes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccentBlue,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        shadowColor: darkAccentBlue.withOpacity(0.5),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Botones de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkAccentBlue,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // FloatingActionButton
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkAccentGreen,
      foregroundColor: Colors.black,
      elevation: 6,
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF1F4788)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF1F4788)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkAccentBlue, width: 2),
      ),
      filled: true,
      fillColor: darkBackgroundSecondary,
      labelStyle: TextStyle(color: darkTextSecondary),
      hintStyle: TextStyle(color: darkTextSecondary),
    ),

    // Iconos más brillantes
    iconTheme: IconThemeData(
      color: darkAccentBlue,
    ),

    // Dividers
    dividerTheme: DividerThemeData(
      color: Color(0xFF1F4788),
      thickness: 1,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: darkCardBackground,
      selectedColor: darkAccentBlue,
      labelStyle: TextStyle(color: darkTextPrimary),
      brightness: Brightness.dark,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return darkAccentBlue;
        }
        return Colors.grey[600];
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return darkAccentBlue.withOpacity(0.5);
        }
        return Colors.grey[800];
      }),
    ),

    // Progress indicators
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: darkAccentBlue,
      circularTrackColor: darkCardBackground,
    ),
  );

  // Obtener tema según preferencia
  static ThemeMode getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'auto':
      default:
        return ThemeMode.system;
    }
  }
}
