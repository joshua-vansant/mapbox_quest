import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:developer';
import 'api_service.dart';
import 'map_screen.dart';

class MyPointAnnotationClickListener extends OnPointAnnotationClickListener {
  APIService apiService = APIService();
  MapScreen mapWidget = const MapScreen();
  late BuildContext context;
  MyPointAnnotationClickListener(this.context);
  
  @override
  void onPointAnnotationClick(PointAnnotation annotation) async {
    LatLng tracker1LatLng, tracker2LatLng;
    Point selectedStopPoint = Point.fromJson((annotation.geometry)!.cast());
    LatLng selectedStopLatLng = LatLng((selectedStopPoint.coordinates.lat).toDouble(), (selectedStopPoint.coordinates.lng).toDouble());
    // Map<String, LatLng> nextStop = apiService.getNextStop(stopLatLng);
    apiService.fetchInitialStateData().then((value) async {
      final tracker1Value = value['tracker1']['value'].toString();
      final lat = double.parse(tracker1Value.split(',')[0]);
      final lng = double.parse(tracker1Value.split(',')[1]);
      tracker1LatLng = LatLng(lat, lng);
      final tracker2Value = value['tracker2']['value'].toString();
      final t2lat = double.parse(tracker2Value.split(',')[0]);
      final t2lng = double.parse(tracker2Value.split(',')[1]);
      tracker2LatLng = LatLng(t2lat, t2lng);
      List<LatLng> coordinates = await apiService.getRouteCoordinates();
      var t1Waypoints = apiService.getWaypoints(coordinates, tracker1LatLng, selectedStopLatLng);
      var t2Waypoints = apiService.getWaypoints(coordinates, tracker2LatLng, selectedStopLatLng);

      String t1ETA = await(apiService.getEstimatedArrivalTime(tracker1LatLng, selectedStopLatLng, waypoints: t1Waypoints));
      String t2ETA = await(apiService.getEstimatedArrivalTime(tracker2LatLng, selectedStopLatLng, waypoints: t1Waypoints));
      // , t2ETA;
      // Map<String, LatLng> nextStop = apiService.getNextStop(stopLatLng);
      // stopLatLng = nextStop.values.first;
      // log('passing coords to waypoints method: ${coordinates.toString()}');
      // apiService.getEstimatedArrivalTime(tracker1LatLng, selectedStopLatLng, waypoints: t1Waypoints).then((value) {
      //   t1ETA = value;
      //   log('t1ETA=$t1ETA');
      // },);
      // apiService.getEstimatedArrivalTime(tracker2LatLng, selectedStopLatLng, waypoints: t2Waypoints).then((value) {
      //   t2ETA = value;
      //   log('t2ETA= $t2ETA');
      // },);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(annotation.textField.toString()),
              content: Text('A shuttle should arrive at ${annotation.textField.toString()} in $t1ETA, $t2ETA seconds.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
    
  }
}