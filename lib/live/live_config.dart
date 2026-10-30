import 'package:firebase_core/firebase_core.dart';

import '../data/mock_data.dart' show PartnerStore;

/// Firebase settings for the live (pilot) version of movr.
///
/// Build with `--dart-define=MOVR_PILOT=true` for live mode (real accounts,
/// bookings and driver location); without it the app is the clickable demo.
/// GitHub Pages serves both: the demo at /Movr/ and the pilot at /Movr/pilot/.
const bool pilotBuild = bool.fromEnvironment('MOVR_PILOT');

const FirebaseOptions? firebaseOptions = pilotBuild ? pilotOptions : null;

/// The movr-pilot Firebase project's web app config (Project settings >
/// Your apps > Web app). These values identify the project; they are not
/// secret. Access is controlled by the security rules in firestore.rules.
const FirebaseOptions pilotOptions = FirebaseOptions(
  apiKey: 'AIzaSyD-aKXeiyrXt24G43n4MEtXPLaZygy1DHo',
  authDomain: 'movr-pilot.firebaseapp.com',
  projectId: 'movr-pilot',
  storageBucket: 'movr-pilot.firebasestorage.app',
  messagingSenderId: '41861758456',
  appId: '1:41861758456:web:348686b5eda2ec9de12a0d',
);

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
