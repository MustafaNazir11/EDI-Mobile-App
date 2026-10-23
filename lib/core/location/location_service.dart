import 'package:geolocator/geolocator.dart';

class SosLocation {
  final double latitude;
  final double longitude;

  const SosLocation({required this.latitude, required this.longitude});

  @override
  String toString() => '$latitude, $longitude';
}

class LocationService {
  Future<SosLocation> getCurrentLocation() async {
    // Check whether location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location is disabled. Enable Location in phone settings.',
      );
    }

    // Check and request permission.
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Enable it in Android Settings.',
      );
    }

    // Obtain the phone's current GPS/location fix.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 30),
      ),
    );

    return SosLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
