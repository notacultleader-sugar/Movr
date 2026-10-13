# movr

On-demand pickup truck and cargo van moving: "muscle and wheels" in under 60 minutes.

This is the **customer app prototype**, built in Flutter so it runs on iOS, Android and the web from one codebase (and stays close to the FlutterFlow route the client suggested). It covers the four screens from the client spec with mocked data, so the whole flow can be clicked through end to end.

| Stage | Screen | What works in the prototype |
| --- | --- | --- |
| 1 | **Request** (`lib/screens/request_screen.dart`) | Live map with moving trucks, "Where are we moving to?" search, quick actions for Recent, Marketplace (FB Marketplace / Craigslist listing fills the pickup and the item) and partner Store |
| 2 | **Quote** (`lib/screens/quote_screen.dart`) | Item › Vehicle › Book progress bar, "Scan Items with AI" camera view, Haul / Van toggle, live orange total, price breakdown |
| 3 | **Active Move** (`lib/screens/active_move_screen.dart`) | Driver card (Marcus · 4.9, Black Ford F-150, BJK-992), live status timeline, truck moving on the map, Call and Message buttons |
| 4 | **Completion** (`lib/screens/completion_screen.dart`) | "Move Complete!", charge summary, $5 / $10 / $15 / Custom tips, 5-star rating and quick tags |

## Pricing

`Quote` in `lib/models/move.dart`:

```
total = tier base ($45 Haul, $75 Van)
      + item handling (Light $2.50, Medium $5, Heavy $7.50, Extra heavy $12.50 each)
      + $2/mile past the first 5 miles
      + $10 safety fee
```

A Haul with one sofa comes to **$62.50**, the figure in the spec. The 25% platform take is applied on the payout side, so it does not appear in the customer price.

## What is mocked

Everything lives in `lib/data/mock_data.dart` and is meant to be swapped for real services:

- **Map:** a self-drawn city (`lib/widgets/city_map.dart`) so the prototype needs no API key. Production: `google_maps_flutter` with live driver GPS.
- **AI scan:** the camera view is simulated and cycles through common items. Production: an on-device vision model or cloud vision API mapping the detected item to a weight class.
- **Dispatch and tracking:** the trip is simulated and fast-forwarded (about 25 seconds).
- **Payments, calls and chat:** UI only. Production: Stripe, a masked calling number, in-app messaging.

## Run it

```bash
flutter pub get
flutter run -d chrome     # or an iOS/Android device
flutter test              # pricing + full click-through test
```

On a desktop browser the app is shown inside a phone frame.

## Web preview

`.github/workflows/deploy-web.yml` publishes the web build to GitHub Pages on every push to the default branch. One-time setup: **Settings › Pages › Source: GitHub Actions**.

## Design

From the client design guide (`lib/theme.dart`): Safety Orange `#FF8C00`, pure black, `#F5F5F5` backgrounds, 16px corner radius on every button and card, Montserrat for headings and Inter for body text (bundled in `assets/fonts`).
