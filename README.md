# movr

On-demand pickup truck and cargo van moving: "muscle and wheels" in under 60 minutes.

This is the **app prototype** (customer and driver sides), built in Flutter so it runs on iOS, Android and the web from one codebase (and stays close to the FlutterFlow route the client suggested). It covers the four screens from the client spec with mocked data, so the whole flow can be clicked through end to end.

| Stage | Screen | What works in the prototype |
| --- | --- | --- |
| 1 | **Request** (`lib/screens/request_screen.dart`) | Live map with moving trucks, "Where are we moving to?" search, quick actions for Recent, Marketplace (FB Marketplace / Craigslist listing fills the pickup and the item) and partner Store |
| 2 | **Quote** (`lib/screens/quote_screen.dart`) | Item › Vehicle › Book progress bar, "Scan Items with AI" camera view, Haul / Van toggle, live orange total, price breakdown |
| 3 | **Active Move** (`lib/screens/active_move_screen.dart`) | Driver card (Marcus · 4.9, Black Ford F-150, BJK-992), live status timeline, truck moving on the map, Call and Message buttons |
| 4 | **Completion** (`lib/screens/completion_screen.dart`) | "Move Complete!", charge summary, $5 / $10 / $15 / Custom tips, 5-star rating and quick tags |

### Driver side (`lib/screens/driver/`)

A start screen lets you choose **I need a move** or **Drive with movr**. You can also switch modes from the profile menu.

| Screen | What works in the prototype |
| --- | --- |
| **Sign-up** (`signup_screen.dart`) | About you, vehicle (pickup, cargo van or box truck, 2014 or newer), document uploads, 50+ lb lifting and background-check consent, then review and approval |
| **Driver home** (`driver_home_screen.dart`) | Go online or offline, today's earnings, incoming job requests with a 15-second countdown, estimated earnings, Accept or Decline |
| **Active job** (`driver_job_screen.dart`) | Drive to pickup, load (photo and strapped-down check), drive to drop-off, complete; call and message the customer |
| **Job complete** (`job_complete_screen.dart`) | Fare, 25% movr fee, tip, and total earnings |
| **Earnings** (`earnings_screen.dart`) | This week's earnings by day, today's moves, cash out |

Driver payout (`DriverPayout` in `lib/models/move.dart`): customer total minus the $10 safety fee is the fare; movr keeps 25% of the fare; the driver keeps the rest plus 100% of tips.

## Pricing

`Quote` in `lib/models/move.dart`:

```
total = tier base ($45 Haul, $75 Van)
      + item handling (Light $2.50, Medium $5, Heavy $7.50, Extra heavy $12.50 each)
      + $2/mile past the first 5 miles
      + $10 safety fee
```

Muscle (labour only: helpers, no vehicle) is priced instead as:

```
total = $35 x helpers x hours + $10 safety fee
```

$35 per helper-hour (plus tips) is the client's rate from their Oct 14 feedback; the revised launch plan had $50.

A Haul with one sofa comes to **$62.50**, the figure in the spec. The 25% platform take is applied on the payout side, so it does not appear in the customer price.

## What is mocked

Everything lives in `lib/data/mock_data.dart` and is meant to be swapped for real services:

- **Map:** a real street map of Duncan, BC (standard OpenStreetMap tiles, no key needed, softened to grey, via `flutter_map`; `lib/widgets/movr_map.dart`). Routes follow real roads from the public OSRM demo server (`lib/services/routing.dart`) and fall back to straight lines if it can't be reached. The addresses, trucks and drivers on it are still made up. OpenStreetMap's free tile server is only for light use, so production needs Google Maps (`google_maps_flutter`, an API key with billing) or a paid tile/routing plan, plus live driver GPS.
- **AI scan:** the camera view is simulated and cycles through common items. Production: an on-device vision model or cloud vision API mapping the detected item to a weight class.
- **Dispatch and tracking:** the trip is simulated and fast-forwarded (about 25 seconds). Job requests for drivers come from a fixed list; there is no server matching customers to drivers yet.
- **Driver onboarding:** document uploads and the background check are simulated, and approval is instant.
- **Payments, calls and chat:** UI only. Production: Stripe, a masked calling number, in-app messaging.

## Pilot (live) mode

`lib/live/` holds a real, Firebase-backed version of the core flow for a small pilot with one driver:

- **Customer:** searches real addresses (OpenStreetMap Nominatim, limited to Vancouver Island) or uses their phone's location, gets a quote, leaves a name and mobile number, and requests a driver. They then watch the driver's live position, ETA and each step until delivery. No card is taken; the customer pays the driver directly.
- **Driver:** signs in with email and password, goes online, sees new requests, accepts one, shares GPS from the phone while the job is open, gets directions and a call button, and taps through arrived, loaded and delivered.

It turns on in builds made with `--dart-define=MOVR_PILOT=true`, which use the `movr-pilot` Firebase project in `lib/live/live_config.dart`; other builds stay the demo described above. GitHub Pages publishes both: the demo at `/Movr/` and the pilot at `/Movr/pilot/`. Partner stores for the pilot go in `pilotStores` in the same file.

Firebase setup, once:

1. Create a Firebase project and add a **Web app**; paste its config into `pilotOptions`.
2. **Authentication:** enable **Anonymous** (customers) and **Email/Password** (drivers).
3. **Firestore:** create the database, then publish `firestore.rules` (`firebase deploy --only firestore:rules`, or paste it into the console's Rules tab).
4. Add each driver: create the user under Authentication, then a Firestore document `drivers/{that user's UID}` with `name`, `vehicle`, `plate`, `phone` and `rating`.

Data lives in `jobs/{id}` (status, contact details, pickup and drop-off, items, price, driver and the driver's latest position).

Limits of the pilot: the driver's location is only shared while the app is open on his phone (a web app can't track in the background), there are no push notifications, and nothing is charged in the app.

Test locally against the Firebase emulators:

```bash
firebase emulators:start --project demo-movr --only auth,firestore
flutter run -d chrome --dart-define=MOVR_EMULATOR=true
```

## Run it

```bash
flutter pub get
flutter run -d chrome     # or an iOS/Android device
flutter test              # pricing, payouts, and click-through tests for both sides
```

On a desktop browser the app is shown inside a phone frame.

## Web preview

`.github/workflows/deploy-web.yml` publishes the web build to GitHub Pages on every push to the default branch. One-time setup: **Settings › Pages › Source: GitHub Actions**.

## Design

From the client design guide (`lib/theme.dart`): Safety Orange `#FF8C00`, pure black, `#F5F5F5` backgrounds, 16px corner radius on every button and card, Montserrat for headings and Inter for body text (bundled in `assets/fonts`).
