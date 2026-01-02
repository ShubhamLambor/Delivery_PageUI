
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  MapUtils._();

  static Future<void> openNavigation({
    required double destinationLat,
    required double destinationLng,
    double? sourceLat,
    double? sourceLng,
  }) async {
    String mapUrl = '';

    if (Platform.isIOS) {
      // Apple Maps URL
      if (sourceLat != null && sourceLng != null) {
        mapUrl = 'https://maps.apple.com/?saddr=$sourceLat,$sourceLng&daddr=$destinationLat,$destinationLng&dirflg=d';
      } else {
        mapUrl = 'https://maps.apple.com/?daddr=$destinationLat,$destinationLng&dirflg=d';
      }
    } else {
      // Google Maps URL
      if (sourceLat != null && sourceLng != null) {
        String mapOptions = [
          'saddr=$sourceLat,$sourceLng',
          'daddr=$destinationLat,$destinationLng',
          'dir_action=navigate'
        ].join('&');
        mapUrl = 'https://www.google.com/maps?$mapOptions';
      } else {
        mapUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving&dir_action=navigate';
      }
    }

    final Uri uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch map navigation';
    }
  }

  static Future<void> openLocation(double lat, double lng) async {
    String mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    final Uri uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open the map';
    }
  }
}
