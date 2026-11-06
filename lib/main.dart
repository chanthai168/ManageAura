import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
void main() {
  DevicePreview.enable(); 

  
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: Scaffold(

        backgroundColor: const Color.fromARGB(255, 232, 233, 235),

        body:Container(
          color: const Color.fromARGB(255, 217, 158, 8),
        ),
          
      ),
    ));
}


