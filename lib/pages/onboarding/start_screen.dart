import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartScreen extends StatefulWidget {
  final void Function(bool) onSubmit;
  final Future<dynamic> googleFontsPending;

  const StartScreen(
      {super.key, required this.onSubmit, required this.googleFontsPending});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
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

  void _startAddingFriends() {
    widget.onSubmit(true);
  }

  void _skipSetup() {
    widget.onSubmit(false);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

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
        var titleStyle = GoogleFonts.londrinaSketch(
          fontSize: 60,
          fontWeight: FontWeight.w900,
          color: colorScheme.surface,
        );
        return Scaffold(
          backgroundColor: colorScheme.primary,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'Friends Builder',
                    style: titleStyle,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'logo/splash.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    color: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                                'An app to help you keep up with your friends that you don’t get to see as often as you’d like.'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                                'It can be really easy to lose touch with people that you care about, regardless of how important they are to you.'),
                          ),
                          Text(
                              'Let’s get you started by adding some friends to keep up with.'),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _skipSetup,
                        child: const Text('Skip'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                          onPressed: _startAddingFriends,
                          child: const Text('Start'))
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
