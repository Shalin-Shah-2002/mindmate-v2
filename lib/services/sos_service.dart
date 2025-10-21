import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SosService {
  static Future<Position?> _getCurrentPosition() async {
    // Request permissions gracefully
    await Permission.locationWhenInUse.request();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 8),
    );
  }

  static String _composeSmsBody({
    required String userName,
    Position? pos,
    String? custom,
  }) {
    final buffer = StringBuffer();
    buffer.write('SOS! $userName needs help.');
    if (custom != null && custom.isNotEmpty) {
      buffer.write(' $custom');
    }
    if (pos != null) {
      final maps =
          'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      buffer.write(' Location: $maps');
    }
    return buffer.toString();
  }

  static Future<bool> sendGroupSms({
    required List<String> phoneNumbers,
    required String userName,
    String? customMessage,
  }) async {
    try {
      final pos = await _getCurrentPosition();
      final body = _composeSmsBody(
        userName: userName,
        pos: pos,
        custom: customMessage,
      );

      // On iOS, we cannot prefill multiple recipients with url_launcher; open composer per-contact
      if (Platform.isIOS) {
        for (final phone in phoneNumbers) {
          final uri = Uri(
            scheme: 'sms',
            path: phone,
            queryParameters: {'body': body},
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
        return true;
      }

      // On Android, comma-separated recipients may be supported by default app
      final recipients = phoneNumbers.join(',');
      final uri = Uri(
        scheme: 'sms',
        path: recipients,
        queryParameters: {'body': body},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
