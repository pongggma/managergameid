# Game ID Ledger (ບັນຊີໄອດີເກມ)

A Flutter app for people who buy and sell game accounts. It is a personal ledger, not a storefront: you record each account you hold, what it cost, what it sold for, who paid, and the app works out profit for you.

Lao version of this file: [README.lo.md](README.lo.md)

## Features

- **One record per game account**: game, account ID, email, password, status, cost, price, sales channel, buyer, paid flag, sold date, note.
- **Only the game name is required.** ID, email and password are optional because some games have no email or password.
- **Automatic profit and ROI**: `profit = price - cost`, `ROI = profit / cost x 100` (hidden when cost is 0).
- **Overview page**: net profit (all time or this month), ROI chip, quick shortcuts, 6-month profit chart with an average line, key figures, latest 5 accounts.
- **All IDs page**: search by game, ID, email, buyer, channel or note; filter chips with live counts (All, In stock, Reserved, Sold, Unpaid).
- **Detail sheet**: tap any card to see everything. Email and password can be revealed and copied with one tap.
- **Add / edit sheet**: cost and price cards with a live profit preview, status pills, sold-date picker, channel quick chips, paid switch.
- **Settings**: currency symbol (LAK, THB, USD), copy all data as CSV, remove demo data.
- **Offline**: everything is stored on the device.
- **Lao UI** with a dark, night-sky look (warm brown to violet background, magenta and butter-yellow accents).

## Requirements

| Tool | Version |
| --- | --- |
| Flutter | 3.22 or newer |
| Dart | 3.4 or newer |

Dependencies (already in `pubspec.yaml`):

| Package | Used for |
| --- | --- |
| `shared_preferences` ^2.2.3 | Saving the ledger on the device |
| `google_fonts` ^6.2.1 | Plus Jakarta Sans and IBM Plex Mono |

## Getting started

1. Create an empty Flutter project (skip if you already have one):

   ```bash
   flutter create game_id_ledger
   cd game_id_ledger
   ```

2. Copy `pubspec.yaml` and the `lib/` folder from this project over the ones in your new project.

3. Install packages and run:

   ```bash
   flutter pub get
   flutter run
   ```

4. **Android release builds:** `google_fonts` downloads fonts at runtime, and release builds need the internet permission. Add this line inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

   Debug builds already have it. iOS needs no change.

On first launch the ledger is empty. Tap **Try demo data** to see the app filled in; demo rows carry a "ຕົວຢ່າງ" (example) label and can be removed from Settings.

## How the numbers are calculated

| Figure | Rule |
| --- | --- |
| Profit of one account | `price - cost` |
| Net profit | Sum of profit for accounts with status **Sold**. "This month" only counts accounts whose sold date is in the current month. |
| ROI chip | Net profit divided by the cost of the sold accounts in the same period |
| In stock | Accounts that are not sold (In stock + Reserved), with the sum of their cost |
| Unpaid | Sold accounts where "Paid" is off, with the sum of their price |
| Average profit per ID | Net profit divided by the number of sold accounts in the period |
| Monthly chart | Profit of sold accounts grouped by sold month, last 6 months; the dashed line is the 6-month average |

Changing the currency in Settings only changes the symbol shown. It does not convert amounts.

## Data and privacy

- All data lives in the device's `shared_preferences` under the key `game-id-ledger-v1`, as one JSON document:

  ```json
  {
    "currency": "LAK",
    "sales": [
      {
        "id": "...",
        "game": "Free Fire",
        "accountId": "FF-48210937",
        "email": "",
        "password": "",
        "status": "sold",
        "cost": 180000,
        "price": 350000,
        "channel": "Facebook",
        "buyer": "@someone",
        "paid": true,
        "soldAt": "2026-10-10",
        "note": "",
        "createdAt": "2026-10-08T09:30:00.000",
        "demo": false
      }
    ]
  }
  ```

- **Emails and passwords are stored unencrypted.** Anyone with access to the unlocked device or its backup may read them. Only record credentials you accept that risk for. To harden this, move the `password` field to [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage).
- CSV export (Settings) includes every field **except the password**.
- Uninstalling the app deletes the data. There is no cloud backup or sync.

## Project structure

```
lib/
  main.dart                        App entry, floating tab bar, three pages
  theme/app_theme.dart             Colours, fonts, night-sky background
  models/sale.dart                 Sale model and status enum
  data/sale_store.dart             Storage, queries, summary, monthly profit, CSV, demo data
  pages/
    overview_page.dart             Hero profit, shortcuts, chart, key figures, latest accounts
    list_page.dart                 Search, filter chips, account cards
    settings_page.dart             Currency, CSV, demo data
  widgets/
    sale_item.dart                 Account card
    sale_detail_sheet.dart         Detail sheet (reveal / copy credentials, delete)
    sale_form_sheet.dart           Add / edit sheet
    profit_chart.dart              Monthly profit chart (CustomPainter)
    ui.dart                        Shared pieces: amount text, chips, panels, sheet frame
  utils/format.dart                Money, dates, chart ticks, game badge colours
```

State is held in one `SaleStore` (a `ChangeNotifier`) created in `main()` and passed down; screens rebuild through `ListenableBuilder`. There is no other state-management package.

## Design tokens

Change the look in one place: `lib/theme/app_theme.dart`.

| Token | Value | Use |
| --- | --- | --- |
| `AppColors.page` | `#08070B` | Page background base |
| `AppColors.magenta` | `#FF14F0` | Primary buttons, selected chips, centre "+" button |
| `AppColors.butter` | `#EBD86A` | Gains, percentage chip, current month bar |
| `AppColors.loss` | `#FF7F9E` | Losses and unpaid warnings |
| `AppColors.muted` / `faint` | `#A39CAD` / `#756E80` | Secondary text |

Fonts: Plus Jakarta Sans for Latin text and numbers, IBM Plex Mono for IDs, emails and passwords. Lao text uses the phone's own Lao font (Noto Sans Lao on Android, Lao Sangam MN on iOS). To work without internet on first launch, bundle the font files under `assets/` and declare them in `pubspec.yaml`.

## Known limitations

- Data is local to one device; no sync, no cloud backup, no CSV import.
- CSV export copies text to the clipboard (paste into Google Sheets or Excel); it does not save a file.
- The monthly chart always shows the last 6 months.
- No automated tests yet.

## Ideas for later

- Encrypted storage for credentials, with an app lock (PIN or biometrics)
- CSV import and file export
- Cloud sync (for example Firebase) so several devices share one ledger
- Per-game and per-channel profit breakdown
- Reminders for reserved accounts that are still unpaid

## License

No license has been chosen yet. Add one (for example MIT) before publishing the code.