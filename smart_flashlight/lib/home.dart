import 'dart:async';

import 'package:daylight/daylight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_flashlight/settings.dart';

import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int minRssi = -85;

  late FlutterBlue flutterBlue;
  List<BluetoothDevice> connectedDevices = [];
  List<ScanResult> receivedBeacons = [];

  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    flutterBlue = FlutterBlue.instance;
    flutterBlue.scanResults.listen((results) async {
      receivedBeacons = [];
      for (ScanResult r in results) {
        if (r.device.name == "Smart Flashlight") {
          receivedBeacons
              .removeWhere((beacon) => beacon.device.id.id == r.device.id.id);
          receivedBeacons.add(r);
          setState(() {});
        }
      }
    });

    flutterBlue.startScan(allowDuplicates: true);
    Timer.periodic(Duration(seconds: 5), autoConnect);

    SharedPreferences.getInstance().then((value) {
      prefs = value;

      if (!prefs!.containsKey("sunset")) {
        prefs!.setBool("sunset", true);
        prefs!.setBool("sunrise", true);

        prefs!.setInt("sunset_delay", 0);
        prefs!.setInt("sunrise_delay", 0);
      }
    });
  }

  void autoConnect(Timer timer) async {
    if (connectedDevices.isNotEmpty && await canConnect) {
      flutterBlue.connectedDevices.then((connDevices) {
        for (BluetoothDevice device in connectedDevices) {
          if (!connDevices.any((element) => element.id.id == device.id.id)) {
            List<ScanResult> received = receivedBeacons
                .where((beacon) => beacon.device.id.id == device.id.id)
                .toList();
            if (received.isNotEmpty && received.first.rssi > minRssi) {
              device.connect();
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Container(
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
              icon: Icon(
                Icons.settings,
                color: Colors.white,
              ),
            ),
          ),
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            child: Text(
              "Devices",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                  child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: receivedBeacons.isEmpty
                          ? Center(
                              child: Text("no devices found"),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: receivedBeacons.length,
                              itemBuilder: (context, index) {
                                BluetoothDevice device =
                                    receivedBeacons[index].device;
                                return ListTile(
                                    leading: Text(
                                        receivedBeacons[index].rssi.toString()),
                                    title: Text(device.name),
                                    subtitle: Text(device.id.id),
                                    trailing: connectedDevices.any((device) =>
                                            device.id.id == device.id.id)
                                        ? TextButton(
                                            child: Container(
                                                color: Colors.lightBlueAccent,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10),
                                                child: Text(
                                                  "Disconnect",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )),
                                            onPressed: () async {
                                              await device.disconnect();
                                              connectedDevices.removeWhere(
                                                  (element) =>
                                                      element.id.id ==
                                                      device.id.id);

                                              setState(() {});
                                            })
                                        : TextButton(
                                            child: Container(
                                                color: Colors.amberAccent,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10),
                                                child: Text(
                                                  "Connect",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )),
                                            onPressed: () async {
                                              if (await canConnect) {
                                                DateTime dt = DateTime.now();
                                                await device.connect();
                                                Duration diff = dt
                                                    .difference(DateTime.now());

                                                print(diff.toString());
                                                connectedDevices.add(device);

                                                setState(() {});
                                              }
                                            }));
                              })))
            ],
          ),
        ));
  }

  Future<bool> get canConnect async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (!permissionGranted(permission)) {
      permission = await Geolocator.requestPermission();
    }
    if (permissionGranted(permission)) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print(serviceEnabled);
      if (!serviceEnabled) {
        return false;
      }
      final location = await Geolocator.getCurrentPosition();
      final daylightLocation =
          DaylightLocation(location.latitude, location.longitude);
      final daylightCalculator = DaylightCalculator(daylightLocation);

      final now = DateTime.now();

      final result = daylightCalculator.calculateForDay(now);
      final sunrise = result.sunrise;
      final sunset = result.sunset;

      if (sunset != null && sunrise != null) {
        return (now.isBefore(sunrise.subtract(
                    Duration(minutes: prefs!.getInt("sunrise_delay")!))) ||
                !prefs!.getBool("sunrise")!) ||
            (now.isAfter(sunset
                    .add(Duration(minutes: prefs!.getInt("sunset_delay")!))) ||
                !prefs!.getBool("sunset")!);
      }
    }
    return false;
  }

  bool permissionGranted(LocationPermission permission) {
    print(permission);
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
