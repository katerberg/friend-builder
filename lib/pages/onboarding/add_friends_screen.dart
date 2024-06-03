import 'package:flutter/material.dart';

class AddFriendsScreen extends StatefulWidget {
  final void Function() onSubmit;

  const AddFriendsScreen({super.key, required this.onSubmit});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreen();
}

class _AddFriendsScreen extends State<AddFriendsScreen> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    onPressed: widget.onSubmit,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                      onPressed: widget.onSubmit, child: const Text('Start'))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
