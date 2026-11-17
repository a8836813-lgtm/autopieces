# AutoPièces (Flutter prototype)

Prototype of a local car-parts marketplace app for a graduation project.
Everything runs on sample data inside the app. There is no backend yet.

## What it shows
- **Home:** search bar, camera button, "Shops near you" slider, category tiles.
- **Search results:** the shops that have the part in stock, with price, distance, stock level, rating and opening hours. Sort by best match, nearest or cheapest. Call and Reserve buttons.
- **Multi-photo scan:** take 3 to 6 photos of a part, the app proposes the top 3 matches (mock scanner), the user confirms, and the shops list appears.
- **Mechanics:** directory with ratings, and repair reports you can search by problem.
- **Profile:** demo client profile and a payment method shown as a token only.
- **Shop mode** (Profile, "Open shop mode"): stock list, scan a part from the shelf to update quantity, price and condition, and confirm reservations.

Try this: search "front brake golf 7", reserve a part at Hamid Grossiste Auto, then open Profile, Shop mode, Reservations tab and confirm it.

## Run it
1. Install Flutter (https://docs.flutter.dev/get-started/install) and Android Studio, or use a phone with USB debugging.
2. In this folder, generate the platform folders:
   ```
   flutter create .
   ```
   Then delete the generated `test/widget_test.dart` (it refers to the default app) and check that `lib/main.dart` is still this project's file.
3. Camera setup
   - Android: in `android/app/build.gradle` (or `build.gradle.kts`) set `minSdk` to 21 or higher. In `android/app/src/main/AndroidManifest.xml` add `<uses-permission android:name="android.permission.CAMERA"/>` above the `<application>` tag.
   - iOS: in `ios/Runner/Info.plist` add `NSCameraUsageDescription` with a short text, for example "Take photos of car parts to identify them".
4. Install packages and run:
   ```
   flutter pub get
   flutter run
   ```
On an emulator or desktop without a camera, the scan screen lets you add demo photos so the whole flow still works.

## Project layout
- `lib/data/models.dart`: data classes (Shop, Part, StockItem, ...)
- `lib/data/repo.dart`: sample data, search, sorting, reservations, stock updates. **This is the file to replace with real API calls later.**
- `lib/services/part_scanner.dart`: scanner interface and the mock scanner. Replace the mock with a real TFLite model plus OCR.
- `lib/screens/`: all screens. `lib/widgets/`: reusable cards.

## Status
Written without being compiled (no Flutter SDK was available where it was written). If `flutter analyze` or `flutter run` reports errors, paste them back and they can be fixed quickly.
