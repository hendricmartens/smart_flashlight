import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  void initState() {
    super.initState();
  }

  void scan() {
    flutterBlue.startScan(timeout: Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
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
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: StreamBuilder<List<ScanResult>>(
                      stream: flutterBlue.scanResults,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(
                            child: Text("no devices found"),
                          );
                        }

                        List<ScanResult> results = snapshot.data!;
                        List<BluetoothDevice> devices = [];

                        for (ScanResult r in results) {
                          if (!devices.any(
                                  (device) => device.id.id == r.device.id.id) &&
                              r.device.name == "Smart Flashlight") {
                            devices.add(r.device);
                          }
                        }

                        return StreamBuilder<Object>(
                            stream: flutterBlue.state,
                            builder: (context, snapshot) {
                              return FutureBuilder<List<BluetoothDevice>>(
                                  future: flutterBlue.connectedDevices,
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container();
                                    }
                                    List<BluetoothDevice> connectedDevices =
                                        snapshot.data!;
                                    return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: devices.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                              title: Text(devices[index].name),
                                              subtitle: Text(devices[index]
                                                  .id
                                                  .id),
                                              trailing: connectedDevices
                                                      .any(
                                                          (device) =>
                                                              devices[index]
                                                                  .id
                                                                  .id ==
                                                              device.id.id)
                                                  ? TextButton(
                                                      child: Container(
                                                          color: Colors
                                                              .lightBlueAccent,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 10),
                                                          child: Text(
                                                            "Disconnect",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          )),
                                                      onPressed: () {
                                                        devices[index]
                                                            .disconnect();
                                                      })
                                                  : TextButton(
                                                      child: Container(
                                                          color:
                                                              Colors
                                                                  .amberAccent,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 10),
                                                          child: Text(
                                                            "Connect",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          )),
                                                      onPressed: () {
                                                        devices[index].connect(
                                                            autoConnect: true);
                                                      }));
                                        });
                                  });
                            });
                      }),
                ),
              )
            ],
          ),
        ));
  }
}
