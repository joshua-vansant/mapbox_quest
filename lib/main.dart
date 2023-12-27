import 'package:flutter/material.dart';
import 'map_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'UCCS Shuttle Tracker',
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}