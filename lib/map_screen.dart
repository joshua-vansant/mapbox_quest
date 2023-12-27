import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
// import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:developer';
import 'api_service.dart';
import 'dart:async';
import 'my_point_annotation_click_listener.dart';

typedef void AddPolylineCallback(PolylineAnnotationOptions polyline);


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  get polylineAnnotationManager => null;

  _MapScreenState createState() => _MapScreenState();


}

class _MapScreenState extends State<MapScreen> {
  
  late MapboxMap mapboxMap;
  late PointAnnotationManager pointAnnotationManager;
  late PolylineAnnotationManager polylineAnnotationManager;
  late SymbolLayer symbolLayer;
  PointAnnotation tracker1 = PointAnnotation(id: 'tracker1',  );
  PointAnnotation tracker2 = PointAnnotation(id: 'tracker2');
  APIService apiService = APIService();
  late MyPointAnnotationClickListener myPointAnnotationClickListener;
  late List<LatLng> coordinates;

      // START: Eagle Rock
      // Lot 540
      // Alpine
      // Lodge
      // Cent
      // UHall
      // Lot 103
      // Cent 
      // Lodge
      // Alpine
      // 540
      // Eagle Rock
      // (580 is not in service currently)
  List<Map<String, LatLng>> shuttleStopsLatLng = [
      {'Eagle Rock Stop': const LatLng(38.90254986221832, -104.8146366565121)},
      {'Lot 540 Stop': const LatLng(38.89998202956692, -104.81070532677619)},
      {'Alpine Stop': const LatLng(38.897690997528024, -104.80652117718797)},
      {'Lodge Stop': const LatLng(38.89436248896465, -104.80542674163705)},
      {'Centennial Hall Stop': const LatLng(38.89193096726863, -104.79925147404836)},
      {'University Hall Stop': const LatLng(38.889464319662274, -104.78774864932078)},
      {'Lot 103 Stop': const LatLng(38.888782337417965, -104.79204688588112)},
    ];

  // int currentIndex = 0;
  // bool isReversed = false;

  // Map<String, LatLng> getNextStop() {
  //   if (!isReversed) {
  //     if (currentIndex < shuttleStopsLatLng.length - 1) {
  //       currentIndex++;
  //     } else {
  //       isReversed = true;
  //       currentIndex--;
  //     }
  //   } else {
  //     if (currentIndex > 0) {
  //       currentIndex--;
  //     } else {
  //       isReversed = false;
  //       currentIndex++;
  //     }
  //   }
  //   return shuttleStopsLatLng[currentIndex];
  // }

  



  // @override
  // void initState() {
  //   super.initState();
  // }
void addPolyline(PolylineAnnotationOptions polyline) {
  PolylineAnnotation polylineAnnotation = PolylineAnnotation(
    id: 'etaLine',
    geometry: polyline.geometry,
    lineColor: polyline.lineColor,
    lineWidth: polyline.lineWidth,
  );
  polylineAnnotationManager.create(polyline);

  // Schedule the removal of the polyline after 10 seconds
  Timer(Duration(seconds: 10), () {
    // Remove the polyline from the map
    polylineAnnotationManager.deleteAll();
  });
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UCCS Shuttle Tracker'),
      ),
      body: Builder(
        builder: (BuildContext context) { 
          return Column(
            children: [
            Expanded(
              child: MapWidget(
                resourceOptions: ResourceOptions(
                  accessToken: 'pk.eyJ1IjoianZhbnNhbnRwdHMiLCJhIjoiY2w1YnI3ejNhMGFhdzNpbXA5MWExY3FqdiJ9.SNsWghIteFZD7DTuI4_FmA',
                ),
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(-104.79610715806722, 38.89094045460431)).toJson(),
                  zoom: 15,
                  pitch: 70,
                  bearing: 300,
                ),
                onMapCreated: (mapboxMap) {
                  _onMapCreated(mapboxMap, context);
                },
                styleUri: 'mapbox://styles/jvansantpts/clpijmftl007i01ol5dlm1dui',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                },
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.indigoAccent),
                  foregroundColor: MaterialStatePropertyAll<Color>(Colors.black),),
                child: const Text('Find Closest Shuttle Stop'),
              ),
            ),
          ],
        );
        }
      )
    );
  }


  void _onMapCreated(MapboxMap mapboxMap, BuildContext context) {
    this.mapboxMap = mapboxMap;
    myPointAnnotationClickListener = MyPointAnnotationClickListener(context, addPolylineCallback: (polyline) {
        addPolyline(polyline);
    },);
    this.mapboxMap.gestures.updateSettings(GesturesSettings(

        ));
    // this.mapboxMap.location.updateSettings(LocationComponentSettings(enabled: true)); // show current position
    this.mapboxMap.compass.updateSettings(CompassSettings(enabled: false,));
    this.mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    mapboxMap.annotations.createPointAnnotationManager().then((value) async {
      pointAnnotationManager = value;
      addShuttleStopsToMap(pointAnnotationManager);
      pointAnnotationManager.addOnPointAnnotationClickListener(myPointAnnotationClickListener);

      Map<String, dynamic> data = await apiService.fetchInitialStateData();
      getTrackers(data);
    });
    
    this.mapboxMap.annotations.createPolylineAnnotationManager().then((value) async {
      polylineAnnotationManager = value;
  //     coordinates = await apiService.getRouteCoordinates();
  //   PolylineAnnotationOptions polyline = PolylineAnnotationOptions(
  //   geometry: LineString(coordinates: coordinates.map((latLng) =>
  //       Position(latLng.longitude, latLng.latitude)).toList()).toJson(),
  //   lineColor: Colors.red.value,
  //     lineWidth: 5,
  // );
  //     addPolyline(polyline);
      // polylineAnnotationManager.create(PolylineAnnotationOptions(
      //   geometry: LineString(coordinates: coordinates.map((latLng) =>
      //   Position(latLng.longitude, latLng.latitude)).toList()).toJson(),
      //   lineColor: Colors.red.value,
      //   lineWidth: 5,
      //   lineBlur: 5
      // ));
    }).catchError((e) {
      log('Error creating polyline: $e');
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      apiService.fetchInitialStateData().then((value) {
        final tracker1Value = value['tracker1']['value'].toString();
        final lat = double.parse(tracker1Value.split(',')[0]);
        final lng = double.parse(tracker1Value.split(',')[1]);
        final tracker1Point = Point(coordinates: Position(lng, lat));
        tracker1.geometry = tracker1Point.toJson();
        updateTrackers(tracker1);
        final tracker2Value = value['tracker2']['value'].toString();
        final t2lat = double.parse(tracker2Value.split(',')[0]);
        final t2lng = double.parse(tracker2Value.split(',')[1]);
        final tracker2Point = Point(coordinates: Position(t2lng, t2lat));
        tracker2.geometry = tracker2Point.toJson();
        updateTrackers(tracker2);
      });
    });
  }




  void addShuttleStopsToMap(PointAnnotationManager pointAnnotationManager) async {
    Uint8List imageBytes = await getImageBytes('assets/bus_stop_red.png');
    for (final stop in shuttleStopsLatLng) {
      final name = stop.keys.first;
      final point = stop.values.first;
      pointAnnotationManager.create(PointAnnotationOptions(
        textField: name,
        textOffset: [0, -1.5],
        geometry: point.toJson(),
        iconSize: .3,
        textSize: 14,
        symbolSortKey: 1,
        image: imageBytes,
        iconAnchor: IconAnchor.BOTTOM,
      ));
    }
  }

  Future<Uint8List> getImageBytes(String imagePath) async {
    final ByteData bytes = await rootBundle.load(imagePath);
    return bytes.buffer.asUint8List();
  }


  void getTrackers(Map<String, dynamic> jsonResponse) async {
    final tracker1Value = jsonResponse['tracker1']['value'].toString();
    // log(tracker1Value);
    final lat = double.parse(tracker1Value.split(',')[0]);
    final lng = double.parse(tracker1Value.split(',')[1]);
    final tracker1Point = Point(coordinates: Position(lng, lat));
    // log('t1Point is: ${tracker1Point.coordinates.lat}, ${tracker1Point.coordinates.lng}');
    pointAnnotationManager.create(PointAnnotationOptions(
      geometry: tracker1Point.toJson(),
      image: await getImageBytes('assets/bus_1.png'),
      iconSize: 1,
      symbolSortKey: 10,
      textField: 'Shuttle 1',
    )).then((value) => tracker1 = value,);
    final tracker2Value = jsonResponse['tracker2']['value'].toString();
    // log(tracker2Value);
    final t2lat = double.parse(tracker2Value.split(',')[0]);
    final t2lng = double.parse(tracker2Value.split(',')[1]);
    final tracker2Point = Point(coordinates: Position(t2lng, t2lat));
      // log('t2Point is: ${tracker2Point.coordinates.lat}, ${tracker2Point.coordinates.lng}');
    pointAnnotationManager.create(PointAnnotationOptions(
      geometry: tracker2Point.toJson(),
      image: await getImageBytes('assets/bus_2.png'),
      iconSize: 1,
      symbolSortKey: 10,
      textField: 'Shuttle 2'
    )).then((value) => tracker2 = value,);
  }


  void updateTrackers(PointAnnotation pointAnnotation){
          var point = Point.fromJson((pointAnnotation.geometry)!.cast());
          var newPoint = Point(
              coordinates: Position(
                  point.coordinates.lng, point.coordinates.lat));
          pointAnnotation.geometry = newPoint.toJson();
          pointAnnotationManager.update(pointAnnotation);
  }


}