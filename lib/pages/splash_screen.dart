import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var titleStyle = TextStyle(
      fontFamily: 'Londrina Sketch',
      fontSize: 60,
      fontWeight: FontWeight.w400,
      backgroundColor: colorScheme.primary,
    );
    // Note: Using fallback font until correct TTF files are downloaded

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
            Image.asset(
              'logo/splash.png',
              fit: BoxFit.cover,
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
