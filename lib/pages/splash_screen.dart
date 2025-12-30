import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var titleStyle = GoogleFonts.londrinaSketch(
      fontSize: 60,
      fontWeight: FontWeight.w900,
      backgroundColor: colorScheme.primary,
    );

    return ColoredBox(
      color: colorScheme.primary,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Friends',
                  style: titleStyle,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              width: 120,
              child: Image.asset(
                'logo/splash.png',
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Builder',
                  style: titleStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
