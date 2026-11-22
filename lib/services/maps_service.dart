import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Google Maps app with a search already typed in.
///
/// Google Maps searches around the phone's current position. If the phone
/// location is off, Google Maps itself asks the user to turn it on with one
/// tap, so the app does not need its own location code.
class MapsService {
  MapsService._();

  /// Text typed in the Google Maps search box for "mechanics near me".
  /// Change it here if you prefer another word (for example "garage").
  static const String mechanicQuery = 'car mechanic';

  /// Same, for the shops that sell car parts.
  static const String partsShopQuery = 'auto parts store';

  static Uri searchUri(String query) => Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': query},
      );

  /// Opens Google Maps (app if installed, browser otherwise) on [query].
  /// Returns false and shows a short message when nothing could be opened.
  static Future<bool> openSearch(BuildContext context, String query) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        searchUri(query),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ),
      );
    }
    return opened;
  }

  static Future<bool> openMechanicsNearMe(BuildContext context) =>
      openSearch(context, mechanicQuery);

  static Future<bool> openPartsShopsNearMe(BuildContext context) =>
      openSearch(context, partsShopQuery);

  /// Shows one place (a mechanic or a shop) by its name and address.
  static Future<bool> openPlace(
    BuildContext context, {
    required String name,
    String? address,
  }) =>
      openSearch(context, address == null ? name : '$name, $address');
}
