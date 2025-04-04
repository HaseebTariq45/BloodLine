import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  final double size;
  final VoidCallback? onTap;

  const BloodTypeBadge({
    super.key,
    required this.bloodType,
    this.size = 45.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get blood group and rhesus factor
    String group = '';
    String rhesus = '';

    if (bloodType.isNotEmpty) {
      if (bloodType.length > 1) {
        group = bloodType.substring(0, bloodType.length - 1);
        rhesus = bloodType.substring(bloodType.length - 1);
      } else {
        group = bloodType;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0xFFFF2D55), // Bright red
              Color(0xFFD10000), // Deep red
            ],
            radius: 0.8,
            focal: Alignment(0.1, 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: -1,
              offset: const Offset(-2, -2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: size * 0.45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      group,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.42,
                        height: 0.9,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    if (rhesus.isNotEmpty)
                      Text(
                        rhesus,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.28,
                          height: 0.9,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: size * 0.05),
                width: size * 0.45,
                height: 1.5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              Text(
                'type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.18,
                  letterSpacing: 0.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0.5, 0.5),
                      blurRadius: 1,
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
