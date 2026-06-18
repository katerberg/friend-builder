# friend_builder

An app to help you build deeper friendships.

## Contributing

Setting up the project should be going through the [normal steps for a flutter application](https://docs.flutter.dev/get-started/install).

Once installed, run the following to build and test the app in debug mode:

```sh
flutter test
flutter run
```

## Deploying to iOS

The application is deployed via [XCode Cloud](https://appstoreconnect.apple.com/teams/ab0ee7c9-ef9e-4f78-8699-b371f4e2de2a/apps/1529389123/ci/groups) to TestFlight. Every push to `main` creates a new build that is deployable to various groups.

## Ideas

Future stats and charts we could build from existing hangout data (`when`, `notes`, `contacts[]`) and friend scheduling data (`frequency`, `isContactable`).

### High-value, low-effort

- Total hangouts in period (headline number — partially shipped via Top Friends subtitle)
- Unique friends seen in period
- Group vs solo — % of hangouts where `contacts.length > 1`
- Calendar vs manual — hangouts whose `notes` start with `"Calendar:"`
- Busiest month — month with most hangouts ("Your social peak: March 2025")
- Most social day of week — Monday–Sunday bar counts from `when.weekday`
- Average group size — mean `contacts.length` per hangout
- Neglected friends — friends with a frequency goal who rank lowest in the period
- Goal adherence % — of contactable friends, how many were seen within their frequency window

### Medium effort, high delight

- Hangouts over time — monthly bar chart for the calendar year
- Streak — longest run of weeks with at least one hangout
- Comeback friend — someone with no hangouts in prior period who appears in current period
- Most improved — biggest jump in hangout count vs previous equivalent period
- First hangout milestone — "You logged your first hangout with Alex this year"
- Social balance — top friend accounts for X% of hangouts (nudge toward breadth)

### Ambitious

- Per-friend timeline sparkline — mini chart of hangouts per month
- Heatmap calendar — GitHub-style grid of hangout days
- Reminder effectiveness — correlate snoozes with eventual hangouts
- Year in review — shareable card (like Spotify Wrapped)

### Chart types mapped to data

| Chart                      | Data source                              |
| -------------------------- | ---------------------------------------- |
| Horizontal bar leaderboard | Per-contact hangout counts (Top Friends) |
| Monthly activity bars      | `when` bucketed by month                 |
| Weekday distribution       | `when.weekday`                           |
| Solo vs group donut        | `contacts.length`                        |
| Goal adherence ring        | `frequency` + latest hangout per friend  |
| Friend share pie           | Top N + "everyone else"                  |
