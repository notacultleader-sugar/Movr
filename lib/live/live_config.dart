import 'package:firebase_core/firebase_core.dart';

import '../data/mock_data.dart' show PartnerStore;

/// Firebase settings for the live (pilot) version of movr.
///
/// Leave [firebaseOptions] null and the app runs as the clickable demo.
/// Fill it in with the web app config from the Firebase console
/// (Project settings > Your apps > Web app > SDK setup > Config) and the
/// app switches to live mode: real accounts, bookings and driver location.
/// These values identify the project; they are not secret. Access is
/// controlled by the security rules in firestore.rules.
const FirebaseOptions? firebaseOptions = null;

/// `flutter run --dart-define=MOVR_EMULATOR=true` talks to the local
/// Firebase emulators instead (used for testing).
const bool useEmulator = bool.fromEnvironment('MOVR_EMULATOR');

/// Lets the emulator run without a real project's config.
const FirebaseOptions emulatorOptions = FirebaseOptions(
  apiKey: 'demo-key',
  appId: '1:000000000000:web:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-movr',
);

/// Real partner stores for the pilot, shown under "Store" on the map
/// screen in live mode. Empty hides the button.
const List<PartnerStore> pilotStores = [];
