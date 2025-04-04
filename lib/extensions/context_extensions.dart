import 'package:flutter/material.dart';

/// Extension methods for BuildContext
extension BuildContextExtensions on BuildContext {
  /// Returns whether the app is in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Returns the current theme's text color
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  
  /// Returns the current theme's primary color
  Color get primaryColor => Theme.of(this).primaryColor;
  
  /// Returns the current theme's background color
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  
  /// Returns the current theme's card color
  Color get cardColor => Theme.of(this).cardColor;
  
  /// Returns screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Returns screen width
  double get screenWidth => screenSize.width;
  
  /// Returns screen height
  double get screenHeight => screenSize.height;
}
