
import 'dart:convert';

class SosMessage {
  final String id;
  final String originDeviceId;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final List<String> route;
  final int maxHops;

  const SosMessage({
    required this.id,
    required this.originDeviceId,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.route = const [],
    this.maxHops = 10,
  });

  int get hopCount => route.length;

  bool hasVisited(String deviceId) => route.contains(deviceId);

  bool get canForward => hopCount < maxHops;

  SosMessage forwardedBy(String deviceId) {
    if (hasVisited(deviceId)) {
      throw StateError('This device has already handled this SOS.');
    }
    if (!canForward) {
      throw StateError('Maximum forwarding hops reached.');
    }

    return SosMessage(
      id: id,
      originDeviceId: originDeviceId,
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
      route: [...route, deviceId],
      maxHops: maxHops,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originDeviceId': originDeviceId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'route': route,
        'hopCount': hopCount,
        'maxHops': maxHops,
      };

  String encode() => jsonEncode(toJson());

  factory SosMessage.fromJson(Map<String, dynamic> json) {
    return SosMessage(
      id: json['id'] as String,
      originDeviceId: json['originDeviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      route: List<String>.from(json['route'] ?? const []),
      maxHops: json['maxHops'] as int? ?? 10,
    );
  }

  factory SosMessage.decode(String data) {
    return SosMessage.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    );
  }
}
