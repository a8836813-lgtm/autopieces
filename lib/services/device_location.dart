import 'package:geolocator/geolocator.dart';

class DevicePosition {
  final double lat;
  final double lng;
  const DevicePosition(this.lat, this.lng);
}

class DeviceLocation {
  static Future<DevicePosition?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return DevicePosition(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
