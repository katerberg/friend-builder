import 'package:flutter/material.dart';
import 'package:friend_builder/utils/calendar_sync.dart';
import 'package:permission_handler/permission_handler.dart';

class CalendarSyncRecommendationScreen extends StatefulWidget {
  final void Function() onSubmit;

  const CalendarSyncRecommendationScreen({super.key, required this.onSubmit});

  @override
  State<CalendarSyncRecommendationScreen> createState() =>
      _CalendarSyncRecommendationScreenState();
}

class _CalendarSyncRecommendationScreenState
    extends State<CalendarSyncRecommendationScreen> {
  void _handleEnableCalendarSync() async {
    final hasPermission = await CalendarSync.requestCalendarPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Calendar permission is required for this feature'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    await CalendarSync.setCalendarSyncEnabled(true);
    widget.onSubmit();
  }

  void _handleSkip() {
    widget.onSubmit();
  }

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
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Never miss a hangout!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Enable calendar sync to automatically track hangouts from your calendar events. '
                        'When you have meetings or events with your friends, they’ll be automatically '
                        'added to your hangout history.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'This helps you keep track of when you last saw your friends and makes it easier '
                        'to maintain those important connections.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: const Text(
                        'Automatically sync calendar events with your friends',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleSkip,
                    child: const Text('Skip for now'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _handleEnableCalendarSync,
                    child: const Text('Enable Calendar Sync'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
