import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../firebase/firebase_auth_service.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.repeat(reverse: true);

    // Check authentication and navigate after a delay
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  // Check if user is already authenticated and navigate accordingly
  Future<void> _checkAuthAndNavigate() async {
    // Access the app provider to check authentication state
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final authService = FirebaseAuthService();
    
    // Check if user is already signed in
    if (authService.isSignedIn) {
      // Refresh user data to ensure we have the latest
      await appProvider.refreshUserData();
      
      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme mode from the app provider
    final appProvider = Provider.of<AppProvider>(context);
    final isDarkMode = appProvider.isDarkMode;

    // Get screen size for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isSmallScreen = screenWidth < 360;
    
    // Get theme colors
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = AppConstants.primaryColor;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color textColor = theme.textTheme.bodyLarge!.color!;
    
    // Define gradient colors based on theme
    final List<Color> gradientColors = isDarkMode 
        ? [
            Colors.black,
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ]
        : [
            Colors.white,
            Color(0xFFF9F9F9),
            Color(0xFFF0F0F0),
          ];

    return Scaffold(
      // Use gradient background instead of solid color
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background circles
              Positioned(
                top: -screenHeight * 0.1,
                left: -screenWidth * 0.2,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * math.pi / 10,
                      child: Container(
                        width: screenWidth * 0.6,
                        height: screenWidth * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.05),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -screenHeight * 0.1,
                right: -screenWidth * 0.2,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_animationController.value * 2 * math.pi / 10,
                      child: Container(
                        width: screenWidth * 0.7,
                        height: screenWidth * 0.7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.05),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Main content - centered both horizontally and vertically
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App name animation with FittedBox for text scaling
                    FadeInUp(
                      from: 30,
                      duration: const Duration(milliseconds: 800),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'BloodLine',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: isSmallScreen ? 32 : 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Tagline animation with FittedBox
                    FadeInUp(
                      from: 30,
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 800),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Give Blood, Save Lives',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    // Loading indicator with custom animation
                    FadeIn(
                      delay: const Duration(milliseconds: 1000),
                      child: SizedBox(
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Additional loading text
                    FadeIn(
                      delay: const Duration(milliseconds: 1200),
                      child: Text(
                        'Loading...',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
