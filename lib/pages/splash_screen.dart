import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Future<dynamic> googleFontsPending;

  const SplashScreen({super.key, required this.googleFontsPending});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Future<void> _assetsLoading;

  @override
  void initState() {
    super.initState();
    _assetsLoading = _loadAssets();
  }

  Future<void> _loadAssets() async {
    await Future.wait([
      widget.googleFontsPending,
      _precacheAssets(),
    ]);
  }

  Future<void> _precacheAssets() async {
    await precacheImage(
      const AssetImage('logo/splash.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var titleStyle = GoogleFonts.londrinaSketch(
      fontSize: 60,
      fontWeight: FontWeight.w900,
      backgroundColor: colorScheme.primary,
    );

    return FutureBuilder(
        future: _assetsLoading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ColoredBox(
              color: colorScheme.primary,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            );
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
