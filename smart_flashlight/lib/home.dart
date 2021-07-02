import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:smart_flashlight/settings.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int minRssi = -80;

  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> connectedDevices = [];
  List<ScanResult> receivedBeacons = [];

  @override
  void initState() {
    super.initState();

    flutterBlue.scanResults.listen((results) {
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
  }

  void autoConnect(Timer timer) {
    if (connectedDevices.isNotEmpty) {
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
          actions: [
            // Container(
            //   child: IconButton(
            //     onPressed: () {
            //       scan();
            //     },
            //     icon: Icon(
            //       Icons.refresh,
            //       color: Colors.white,
            //     ),
            //   ),
            // )
          ],
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
                                              await device.connect();
                                              connectedDevices.add(device);
                                              setState(() {});
                                            }));
                              })))
            ],
          ),
        ));
  }
}
