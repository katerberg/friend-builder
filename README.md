# friend_builder

An app to help you build deeper friendships.

## Contributing

Setting up the project should be going through the [normal steps for a flutter application](https://docs.flutter.dev/get-started/install).

Once installed, run the following to build and test the app in debug mode:

```sh
flutter test
flutter run
```

### Setting up storage

The application uses Firebase as cloud storage synced from the device. This isn't necessary for initial testing since the app functions fine without any connection, but if you want to test syncing, you will need to run the following after you have [set up Firebase CLI](https://firebase.google.com/docs/cli?hl=en&authuser=0#install-cli-mac-linux) to verify you have permissions:

```sh
firebase login
firebase projects:list
```

### Deploying to iOS

The application is deployed via [XCode Cloud](https://appstoreconnect.apple.com/teams/ab0ee7c9-ef9e-4f78-8699-b371f4e2de2a/apps/1529389123/ci/groups) to TestFlight. Every push to `main` creates a new build that is deployable to various groups.