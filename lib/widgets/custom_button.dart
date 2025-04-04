import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ButtonType { primary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isFullWidth = true,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double buttonHeight = height ?? (isSmallScreen ? 45.0 : 50.0);
    final double buttonFontSize = fontSize ?? (isSmallScreen ? 14.0 : 16.0);
    final double iconSize = isSmallScreen ? 16.0 : 20.0;
    final double loaderSize = isSmallScreen ? 16.0 : 20.0;
    final EdgeInsetsGeometry buttonPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12.0 : 16.0,
          vertical: isSmallScreen ? 8.0 : 12.0,
        );

    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(
          context,
          buttonHeight,
          buttonFontSize,
          iconSize,
          loaderSize,
          buttonPadding,
        );
      case ButtonType.outline:
        return _buildOutlineButton(
          context,
          buttonHeight,
          buttonFontSize,
          iconSize,
          loaderSize,
          buttonPadding,
        );
      case ButtonType.text:
        return _buildTextButton(
          context,
          buttonFontSize,
          iconSize,
          loaderSize,
          buttonPadding,
        );
    }
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    double buttonHeight,
    double fontSize,
    double iconSize,
    double loaderSize,
    EdgeInsetsGeometry padding,
  ) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          elevation: 2,
          padding: padding,
        ),
        child: _buildButtonContent(fontSize, iconSize, loaderSize),
      ),
    );
  }

  Widget _buildOutlineButton(
    BuildContext context,
    double buttonHeight,
    double fontSize,
    double iconSize,
    double loaderSize,
    EdgeInsetsGeometry padding,
  ) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          padding: padding,
        ),
        child: _buildButtonContent(fontSize, iconSize, loaderSize),
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    double fontSize,
    double iconSize,
    double loaderSize,
    EdgeInsetsGeometry padding,
  ) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        padding: padding,
      ),
      child: _buildButtonContent(fontSize, iconSize, loaderSize),
    );
  }

  Widget _buildButtonContent(
    double fontSize,
    double iconSize,
    double loaderSize,
  ) {
    if (isLoading) {
      return SizedBox(
        width: loaderSize,
        height: loaderSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
    );
  }
}
