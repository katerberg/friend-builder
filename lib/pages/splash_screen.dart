import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  final Future<dynamic> googleFontsPending;

  const SplashScreen({super.key, required this.googleFontsPending});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var titleStyle = GoogleFonts.getFont(
      'Londrina Sketch',
      fontSize: 60,
      fontWeight: FontWeight.w900,
      backgroundColor: colorScheme.primary,
    );

    return FutureBuilder(
        future: googleFontsPending,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox();
          }

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
        });
  }
}
