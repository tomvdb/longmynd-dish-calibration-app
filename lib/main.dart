import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calibration_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Longmynd Dish Calibration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Longmynd Dish Calibration'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //String longmyndHostInput = "ws://192.168.0.178:8080";

  late String longmyndHost;

  String title = "";

  TextEditingController longmyndHostTextController = TextEditingController();

  late Future<String> _futureLongmynd;

  @override
  void initState() {
    super.initState();
    _futureLongmynd = loadPreferences();
  }

  void refreshSettings() {
    setState(() {
      _futureLongmynd = loadPreferences();
    });
  }

  Future<String> loadPreferences() async {
    debugPrint("Load Preferences Start");

    final prefs = await SharedPreferences.getInstance();

    longmyndHost =
        prefs.getString("longmynd_host") ?? "ws://192.168.0.172:8080";

    return longmyndHost;
  }

  void saveSettings(String lmhost) async {
    await Future.wait([savePreferences(lmhost)]);
  }

  Future<bool> savePreferences(String longmyndHost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("longmynd_host", longmyndHost);
    return true;
  }

  void showSettings() async {
    debugPrint("Show Settings Dialog");

    longmyndHostTextController.text = longmyndHost;

    var lmhost = await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text("Settings"),
              titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20),
              actionsOverflowButtonSpacing: 20,
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, 'Cancel');
                    },
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      //saveSettings(longmyndHostTextController.text);
                      Navigator.pop(context, longmyndHostTextController.text);
                    },
                    child: const Text("Save")),
              ],
              content: Container(
                  width: double.maxFinite,
                  child: ListView(
                      //crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Longmynd host:"),
                        TextFormField(
                          controller: longmyndHostTextController,
                        ),
                      ])),
            ));

    if (lmhost != "Cancel") {
      debugPrint(lmhost);
      await savePreferences(lmhost);
      refreshSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _futureLongmynd,
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(widget.title),
                  actions: [
                    IconButton(
                        onPressed: () {
                          showSettings();
                          refreshSettings();
                        },
                        icon: const Icon(Icons.settings))
                  ],
                ),
                body: ListView(children: <Widget>[
                  CalibrationWidget(
                    longmyndip: snapshot.data!,
                  ),
                ]));
          } else {
            return const Text("Waiting");
          }
        });
  }
}
