import 'package:flutter/material.dart';
import 'app_localization.dart';

class LocalizationHelper {
  static String translate(BuildContext context, String key) {
    return AppLocalizations.of(context).translate(key);
  }

  // Helper to get a translated string directly
  static String get(BuildContext context, String key) {
    return key.tr(context);
  }
} 