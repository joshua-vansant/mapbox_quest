import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';
import 'map_screen.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
// import 'package:latlong2/latlong.dart';
import 'dart:math' show asin, cos, sin, sqrt;

class APIService {
  MapScreen mapWidget = const MapScreen();
  List<LatLng>? _cachedRouteCoordinates;
  // List<Map<String, LatLng>> busStopsLatLng = [
  //     {'Eagle Rock Stop': const LatLng(38.90254986221832, -104.8146366565121)},
  //     {'Lot 540 Stop': const LatLng(38.89998202956692, -104.81070532677619)},
  //     {'Alpine Stop': const LatLng(38.897690997528024, -104.80652117718797)},
  //     {'Lodge Stop': const LatLng(38.89436248896465, -104.80542674163705)},
  //     {'Centennial Hall Stop': const LatLng(38.89193096726863, -104.79925147404836)},
  //     {'University Hall Stop': const LatLng(38.889464319662274, -104.78774864932078)},
  //     {'Lot 103 Stop': const LatLng(38.888782337417965, -104.79204688588112)},
  //     {'Centennial Hall Stop': const LatLng(38.89193096726863, -104.79925147404836)},
  //     {'Lodge Stop': const LatLng(38.89436248896465, -104.80542674163705)},
  //     {'Alpine Stop': const LatLng(38.897690997528024, -104.80652117718797)},
  //     {'Lot 540 Stop': const LatLng(38.89998202956692, -104.81070532677619)},
  //   ];

  List<Map<String, LatLng>> busStopsLatLng = [
  {'Eagle Rock Stop': LatLng(38.90255, -104.814637)},
  {'Lot 540 Stop': LatLng(38.899982, -104.810705)},
  {'Alpine Stop': LatLng(38.897691, -104.806521)},
  {'Lodge Stop': LatLng(38.894362, -104.805427)},
  {'Centennial Hall Stop': LatLng(38.891931, -104.799251)},
  {'University Hall Stop': LatLng(38.889464, -104.787749)},
  {'Lot 103 Stop': LatLng(38.888782, -104.792047)},
  {'Centennial Hall Stop': LatLng(38.891931, -104.799251)},
  {'Lodge Stop': LatLng(38.894362, -104.805427)},
  {'Alpine Stop': LatLng(38.897691, -104.806521)},
  {'Lot 540 Stop': LatLng(38.899982, -104.810705)},
];

  Future<dynamic> fetchInitialStateData() async {
  final response = await http.get(Uri.parse(
      'https://api.init.st/data/v1/events/latest?accessKey=ist_rg6P7BFsuN8Ekew6hKsE5t9QoMEp2KZN&bucketKey=jmvs_pts_tracker'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load data');
    }
  }


Future<List<LatLng>> getRouteCoordinates() async {
    if(_cachedRouteCoordinates != null) {
      return _cachedRouteCoordinates!;
    }
    const String apiKey = 'pk.eyJ1IjoianZhbnNhbnRwdHMiLCJhIjoiY2w1YnI3ejNhMGFhdzNpbXA5MWExY3FqdiJ9.SNsWghIteFZD7DTuI4_FmA';
    List<Map<String, LatLng>> originalCoordinates = busStopsLatLng;

    final List<LatLng> snappedCoordinates = await getSnappedRouteCoordinates(originalCoordinates, apiKey);
    _cachedRouteCoordinates = snappedCoordinates;
    return snappedCoordinates;
  }

  Future<List<LatLng>> getSnappedRouteCoordinates(List<Map<String, LatLng>> originalCoordinates, String apiKey) async {
    if(_cachedRouteCoordinates != null){
      // log(_cachedRouteCoordinates.toString());
      return _cachedRouteCoordinates!;
    }
    const String mapMatchingEndpoint = 'https://api.mapbox.com/matching/v5/mapbox/driving/';
    final List<String> coordinatesList = originalCoordinates
        .map((stop) => '${stop.values.first.longitude},${stop.values.first.latitude}')
        .toList();

    final String url = '$mapMatchingEndpoint${coordinatesList.join(';')}?geometries=geojson&access_token=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('matchings') && data['matchings'].isNotEmpty) {
          List<LatLng> snappedCoordinates = [];
          for (final matching in data['matchings']) {
            final List<dynamic> coordinates = matching['geometry']['coordinates'];
            for (final coord in coordinates) {
              final LatLng snappedCoordinate = LatLng(coord[1].toDouble(), coord[0].toDouble());
              snappedCoordinates.add(snappedCoordinate);
            }
          }
          // Convert List<Map<String, LatLng>> to List<LatLng>
          List<LatLng> convertedCoordinates = originalCoordinates
              .map((map) => map.values.first) // Extract the LatLng from each map
              .toList();
          _cachedRouteCoordinates = snappedCoordinates;
          // log('merging coords');
          List<LatLng> mergedCoordinates= mergeCoordinates(snappedCoordinates, convertedCoordinates);
          snappedCoordinates = mergedCoordinates;
          return snappedCoordinates;
        } else {
          log('Error: Invalid or missing matchings data');
          return [];
        }
      } else {
        log('Error: ${response.statusCode}');
        log('Response body from getSnappedRoutes: ${response.body}');
        return [];
      }
    } catch (e) {
      log('Error: $e');
      return [];
    }
  }

List<LatLng> mergeCoordinates(List<LatLng> snappedCoordinates, List<LatLng> originalCoordinates) {
  List<LatLng> mergedCoordinates = List<LatLng>.from(snappedCoordinates); // Create a copy of snappedCoordinates
  for (int i = 0; i < originalCoordinates.length; i++) {
    LatLng originalCoord = originalCoordinates[i];
    // Find the closest point in snappedCoordinates
    int closestIndex = 0;
    double closestDistance = double.infinity;
    for (int j = 0; j < mergedCoordinates.length; j++) {
      double distance = distanceBetween(originalCoord, mergedCoordinates[j]);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = j;
      }
    }
    // Insert the original coordinate at the closestIndex in mergedCoordinates
    mergedCoordinates.insert(closestIndex, originalCoord);
  }
  // snappedCoordinates = mergedCoordinates;
  // log('mergedCoordinates = ${mergedCoordinates.toString()}');
  return mergedCoordinates;
}

double distanceBetween(LatLng latLng1, LatLng latLng2) {
  const double earthRadius = 6371000; // in meters

  double lat1 = latLng1.latitude * (pi / 180);
  double lon1 = latLng1.longitude * (pi / 180);
  double lat2 = latLng2.latitude * (pi / 180);
  double lon2 = latLng2.longitude * (pi / 180);

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * asin(sqrt(a));
  double distance = earthRadius * c;

  return distance;
}

  // final String apiKey = '7614t1xj1BM7awzGEZe81DnqQrjDzUMG';
  Future<String> getEstimatedArrivalTime(LatLng origin, LatLng destination, {List<LatLng>? waypoints}) async {
    final String apiKey = '7614t1xj1BM7awzGEZe81DnqQrjDzUMG';
    String url = 'https://www.mapquestapi.com/directions/v2/route?key=$apiKey&from=${origin.latitude},${origin.longitude}&to=${destination.latitude},${destination.longitude}';
    
    if (waypoints != null && waypoints.isNotEmpty) {
      final String waypointsString = waypoints.map((point) => 'via=${point.latitude},${point.longitude}').join('&');
      url = '$url&$waypointsString';
      // log('finalURL = ${url.toString()}');
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final int seconds = data['route']['realTime'];
      final DateTime now = DateTime.now();
      final DateTime arrivalTime = now.add(Duration(seconds: seconds));
      return DateFormat.jm().format(arrivalTime);
    } else {
      throw Exception('Failed to get the ETA: ${response.statusCode}');
    }
  }

List<LatLng> getWaypoints(List<LatLng> snappedRouteCoordinates, LatLng startLatLng, LatLng endLatLng, int numberOfWaypoints) {
  List<LatLng> waypoints = [];
  int startIndex = 0;
  int endIndex = 0;
  double closestStartDistance = double.infinity;
  double closestEndDistance = double.infinity;

   // Find the index of the closest point to startLatLng and endLatLng
  for (int i = 0; i < snappedRouteCoordinates.length; i++) {
    double startDistance = distanceBetween(startLatLng, snappedRouteCoordinates[i]);
    double endDistance = distanceBetween(endLatLng, snappedRouteCoordinates[i]);
    if (startDistance < closestStartDistance) {
      closestStartDistance = startDistance;
      startIndex = i;
      log('startIndex in GW = $startIndex');
    }
    if (endDistance < closestEndDistance) {
      closestEndDistance = endDistance;
      endIndex = i;
      log('endIndex in GW = $endIndex');
    }
  }

  // Calculate the step size to get the desired number of evenly spaced points
int totalPoints;
if (startIndex <= endIndex) {
  totalPoints = endIndex - startIndex;
} else {
  totalPoints = snappedRouteCoordinates.length - startIndex + endIndex;
}
int stepSize = (totalPoints / (numberOfWaypoints + 1)).round();

// Add points between the startIndex and endLatLng to waypoints
int i = startIndex;
int count = 0;
while (count < totalPoints) {
  waypoints.add(snappedRouteCoordinates[i]);
  i += stepSize;
  if (i >= snappedRouteCoordinates.length) {
    i = i - snappedRouteCoordinates.length; // Wrap around to the beginning
  }
  count += stepSize;
}
waypoints.add(endLatLng); // Add the endLatLng


  return waypoints;
}







}