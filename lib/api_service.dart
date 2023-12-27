import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';
import 'map_screen.dart';
import 'dart:developer';
import 'package:intl/intl.dart';

class APIService {
  MapScreen mapWidget = const MapScreen();
  List<LatLng>? _cachedRouteCoordinates;
  List<Map<String, LatLng>> busStopsLatLng = [
      {'Eagle Rock Stop': const LatLng(38.90254986221832, -104.8146366565121)},
      {'Lot 540 Stop': const LatLng(38.89998202956692, -104.81070532677619)},
      {'Alpine Stop': const LatLng(38.897690997528024, -104.80652117718797)},
      {'Lodge Stop': const LatLng(38.89436248896465, -104.80542674163705)},
      {'Centennial Hall Stop': const LatLng(38.89193096726863, -104.79925147404836)},
      {'University Hall Stop': const LatLng(38.889464319662274, -104.78774864932078)},
      {'Lot 103 Stop': const LatLng(38.888782337417965, -104.79204688588112)},
      {'Centennial Hall Stop': const LatLng(38.89193096726863, -104.79925147404836)},
      {'Lodge Stop': const LatLng(38.89436248896465, -104.80542674163705)},
      {'Alpine Stop': const LatLng(38.897690997528024, -104.80652117718797)},
      {'Lot 540 Stop': const LatLng(38.89998202956692, -104.81070532677619)},
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
          final List<LatLng> snappedCoordinates = [];
          for (final matching in data['matchings']) {
            final List<dynamic> coordinates = matching['geometry']['coordinates'];
            for (final coord in coordinates) {
              final LatLng snappedCoordinate = LatLng(coord[1].toDouble(), coord[0].toDouble());
              snappedCoordinates.add(snappedCoordinate);
            }
          }
          _cachedRouteCoordinates = snappedCoordinates;
          // log(snappedCoordinates.toString());
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

  // final String apiKey = '7614t1xj1BM7awzGEZe81DnqQrjDzUMG';
  Future<String> getEstimatedArrivalTime(LatLng origin, LatLng destination, {List<LatLng>? waypoints}) async {
    final String apiKey = '7614t1xj1BM7awzGEZe81DnqQrjDzUMG';
    String url = 'https://www.mapquestapi.com/directions/v2/route?key=$apiKey&from=${origin.latitude},${origin.longitude}&to=${destination.latitude},${destination.longitude}';
    
    if (waypoints != null && waypoints.isNotEmpty) {
      final String waypointsString = waypoints.map((point) => 'via=${point.latitude},${point.longitude}').join('&');
      url = '$url&$waypointsString';
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

List<LatLng> getWaypoints(List<LatLng> snappedRouteCoordinates, LatLng startLatLng, LatLng endLatLng) {
  List<LatLng> waypoints = [];
  if (snappedRouteCoordinates.isNotEmpty) {
    waypoints.add(startLatLng);
    for (LatLng point in snappedRouteCoordinates) {
      if ((point.latitude > startLatLng.latitude && point.latitude < endLatLng.latitude) &&
          (point.longitude > startLatLng.longitude && point.longitude < endLatLng.longitude)) {
        waypoints.add(point);
      }
    }
    waypoints.add(endLatLng);
  }
  log('returning waypoints=${waypoints.toString()}');
  return waypoints;
}

}