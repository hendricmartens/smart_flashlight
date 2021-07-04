import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sunset = true;
  Duration sunset_delay = Duration();

  bool sunrise = true;
  Duration sunrise_delay = Duration();

  bool initialized = false;

  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((value) {
      prefs = value;
      if (prefs!.containsKey("sunset")) {
        sunset = prefs!.getBool("sunset")!;
        sunrise = prefs!.getBool("sunrise")!;

        sunset_delay = Duration(minutes: prefs!.getInt("sunset_delay")!);
        sunrise_delay = Duration(minutes: prefs!.getInt("sunrise_delay")!);

        setState(() {});
      } else {
        prefs!.setBool("sunset", sunset);
        prefs!.setBool("sunrise", sunrise);

        prefs!.setInt("sunset_delay", sunset_delay.inMinutes);
        prefs!.setInt("sunrise_delay", sunrise_delay.inMinutes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 30, left: 30),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 20),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          sunset = !sunset;
                        });
                        prefs?.setBool("sunset", sunset);
                      },
                      child: Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sunset ? Colors.blueAccent : Colors.grey),
                        child: sunset
                            ? Icon(
                                Icons.check,
                                size: 20.0,
                                color: Colors.white,
                              )
                            : Icon(
                                Icons.check_box_outline_blank,
                                size: 20.0,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  Text("turns on after sunset, "),
                  Container(
                      margin: EdgeInsets.only(right: 10),
                      child: Text("delay: ")),
                  !sunset
                      ? Container()
                      : GestureDetector(
                          onTap: () {
                            showMaterialModalBottomSheet(
                                expand: false,
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Container(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              3,
                                      color: Colors.white,
                                      child: Column(
                                        children: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text("Done"))
                                              ]),
                                          Expanded(
                                            child: CupertinoTimerPicker(
                                              mode: CupertinoTimerPickerMode.hm,
                                              onTimerDurationChanged:
                                                  (Duration duration) =>
                                                      setState(() {
                                                this.sunset_delay = duration;
                                                prefs?.setInt(
                                                    "sunset_delay",
                                                    this
                                                        .sunset_delay
                                                        .inMinutes);
                                              }),
                                              initialTimerDuration:
                                                  this.sunset_delay,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                                color: Colors.grey.withOpacity(0.7)),
                            child: Text(
                              DateFormat('HH:mm').format(
                                  DateTime(DateTime.now().year)
                                      .add(sunset_delay)),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(right: 20),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        sunrise = !sunrise;
                      });
                      prefs?.setBool("sunrise", sunrise);
                    },
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sunrise ? Colors.blueAccent : Colors.grey),
                      child: sunrise
                          ? Icon(
                              Icons.check,
                              size: 20.0,
                              color: Colors.white,
                            )
                          : Icon(
                              Icons.check_box_outline_blank,
                              size: 20.0,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                ),
                Text("turns off after sunrise, "),
                Container(
                    margin: EdgeInsets.only(right: 10), child: Text("delay: ")),
                !sunrise
                    ? Container()
                    : GestureDetector(
                        onTap: () {
                          showMaterialModalBottomSheet(
                              expand: false,
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    color: Colors.white,
                                    child: Column(
                                      children: [
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: Text("Done"))
                                            ]),
                                        Expanded(
                                          child: CupertinoTimerPicker(
                                            mode: CupertinoTimerPickerMode.hm,
                                            onTimerDurationChanged:
                                                (Duration duration) =>
                                                    setState(() {
                                              this.sunrise_delay = duration;
                                              if (prefs != null) {
                                                prefs?.setInt(
                                                    "sunrise_delay",
                                                    this
                                                        .sunrise_delay
                                                        .inMinutes);
                                              }
                                            }),
                                            initialTimerDuration:
                                                this.sunrise_delay,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ));
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30)),
                              color: Colors.grey.withOpacity(0.7)),
                          child: Text(
                            DateFormat('HH:mm').format(
                                DateTime(DateTime.now().year)
                                    .add(sunrise_delay)),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
