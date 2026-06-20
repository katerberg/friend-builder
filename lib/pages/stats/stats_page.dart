import 'package:flutter/material.dart';
import 'package:friend_builder/pages/stats/sections/group_solo_section.dart';
import 'package:friend_builder/pages/stats/sections/hangouts_per_month_section.dart';
import 'package:friend_builder/pages/stats/sections/top_friends_section.dart';
import 'package:friend_builder/pages/stats/sections/weekday_histogram_section.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/utils/calendar_year.dart';

class StatsPage extends StatefulWidget {
  final Storage storage;

  const StatsPage({
    super.key,
    required this.storage,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _isLoadingHeader = true;
  int _hangoutCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    final hangoutCount = await widget.storage.getHangoutCountForCalendarYear();

    if (!mounted) return;

    setState(() {
      _hangoutCount = hangoutCount;
      _isLoadingHeader = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = calendarYearBounds().year;
    final subtitle = formatHangoutCountSubtitle(year, _hangoutCount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_isLoadingHeader)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        TopFriendsSection(storage: widget.storage),
        const SizedBox(height: 16),
        HangoutsPerMonthSection(storage: widget.storage),
        const SizedBox(height: 16),
        GroupSoloSection(storage: widget.storage),
        const SizedBox(height: 16),
        WeekdayHistogramSection(storage: widget.storage),
      ],
    );
  }
}
