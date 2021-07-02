import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> connectedDevices = [];
  List<BluetoothDevice> foundDevices = [];

  @override
  void initState() {
    super.initState();
  }

  void scan() {
    foundDevices = [];
    flutterBlue.startScan(timeout: Duration(seconds: 5));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!foundDevices.any((device) => device.id.id == r.device.id.id) &&
            r.device.name == "Smart Flashlight") {
          foundDevices.add(r.device);

          setState(() {});
        }
      }
    });
    setState(() {});
  }

  void autoConnect(Timer timer) {
    if (connectedDevices.isNotEmpty) {
      flutterBlue.connectedDevices.then((connDevices) {
        for (BluetoothDevice device in connectedDevices) {
          if (!connDevices.any((element) => element.id.id == device.id.id)) {
            device.connect();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(Duration(seconds: 5), autoConnect);

    return Scaffold(
        appBar: AppBar(
          leading: Container(
            child: IconButton(
              onPressed: () {},
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
            StreamBuilder<bool>(
                stream: flutterBlue.isScanning,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  return snapshot.data!
                      ? Container()
                      : Container(
                          child: IconButton(
                            onPressed: () {
                              scan();
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                        );
                })
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                  child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: foundDevices.isEmpty
                          ? Center(
                              child: Text("no devices found"),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: foundDevices.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                    title: Text(foundDevices[index].name),
                                    subtitle: Text(foundDevices[index].id.id),
                                    trailing: connectedDevices.any((device) =>
                                            foundDevices[index].id.id ==
                                            device.id.id)
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
                                              await foundDevices[index]
                                                  .disconnect();
                                              connectedDevices.removeWhere(
                                                  (element) =>
                                                      element.id.id ==
                                                      foundDevices[index]
                                                          .id
                                                          .id);
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
                                              await foundDevices[index]
                                                  .connect();
                                              connectedDevices
                                                  .add(foundDevices[index]);
                                              setState(() {});
                                            }));
                              })))
            ],
          ),
        ));
  }
}
