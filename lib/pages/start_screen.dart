import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartScreen extends StatefulWidget {
  final void Function(bool) onSubmit;
  final Future<dynamic> googleFontsPending;

  const StartScreen({
    super.key,
    required this.googleFontsPending,
    required this.onSubmit,
  });

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
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
      future: widget.googleFontsPending,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        }
        var titleStyle = GoogleFonts.getFont(
          'Londrina Sketch',
          fontSize: 60,
          fontWeight: FontWeight.w900,
          color: colorScheme.background,
        );
        return Scaffold(
          backgroundColor: colorScheme.primary,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                                'An app to help you keep up with your friends that you don’t get to see as often as you’d like.'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                                'Let’s get you started by adding some friends.'),
                          ),
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
