import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CalibrationWidget extends StatefulWidget {
  final String longmyndip;

  const CalibrationWidget({Key? key, this.longmyndip = ""}) : super(key: key);

  @override
  State<CalibrationWidget> createState() => _CalibrationWidget();
}

class _CalibrationWidget extends State<CalibrationWidget> {
  final Map<int, String> demod_state_lookup = {
    0: "Initializing",
    1: "Hunting",
    2: "Header",
    3: "Lock DVB-S",
    4: "Lock DVB-S2 "
  };

  var values = <FlSpot>[];
  var averages = <FlSpot>[];
  double prevAverage = 0;
  int counter = 0;

  late DateTime previousTime;
  @override
  void initState() {
    super.initState();
    previousTime = DateTime.now();
    debugPrint("init State");
  }

  @override
  Widget build(BuildContext context) {
    if (widget.longmyndip.isNotEmpty) {
      bool error = false;

      var channel;

      try {
        channel = WebSocketChannel.connect(Uri.parse(widget.longmyndip),
            protocols: ["monitor"]);
      } catch (_) {
        error = true;
      }

      if (error == true) {
        return const Text("Not Connected");
      }

      return StreamBuilder(
          stream: channel.stream,
          builder: ((context, snapshot) {
            late Map<String, dynamic> data;

            if (snapshot.hasData) {
              data = json.decode(snapshot.data.toString());

              if (data['packet']['rx']['mer'] >= 0) {
                values.add(FlSpot(
                    counter.toDouble(), data['packet']['rx']['mer'] / 10));
              }

              if (values.length > 200) {
                values.removeRange(0, 1);
              }

              double sum = 0;

              for (var x = 0; x < values.length; x++) {
                sum += values[x].y;
              }

              sum = sum / values.length;
              //sum = num.parse(sum.toStringAsFixed(2)).toDouble();
              DateTime current = DateTime.now();

              var difference =
                  (current.difference(previousTime).inSeconds).abs();

              if (difference > 2) {
                averages.add(FlSpot(
                    DateTime.now().millisecondsSinceEpoch.toDouble(),
                    num.parse(sum.toStringAsFixed(2)).toDouble()));

                previousTime = DateTime.now();
              }

              if (averages.length > 20) {
                averages.removeRange(0, 1);
              }

              String? locked =
                  demod_state_lookup[data['packet']['rx']['demod_state']];

              String frequency = "${data['packet']['rx']['frequency']} Hz";

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    snapshot.hasData
                        ? (data['packet']['rx']['mer'] / 10)
                                .toStringAsFixed(2) +
                            " dB"
                        : '',
                    style: const TextStyle(fontSize: 90),
                  ),
                  Text(
                    "${sum.toStringAsFixed(sum.truncateToDouble() == sum ? 0 : 2)} dB",
                    style: TextStyle(
                        fontSize: 90,
                        color:
                            values.length >= 200 ? Colors.green : Colors.red),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      padding: const EdgeInsets.all(50),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent)),
                      child: LineChart(
                        LineChartData(
                            titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false,
                                        getTitlesWidget: (value, title) {
                                          return Text(num.parse(
                                                  value.toStringAsFixed(1))
                                              .toString());
                                        })),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false,
                                        getTitlesWidget: (value, title) {
                                          var dt = DateTime
                                              .fromMillisecondsSinceEpoch(
                                                  value.toInt());
                                          return Text(
                                              "${dt.minute}.${dt.second}");
                                        }))),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(spots: averages),
                            ]),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(locked.toString(),
                        style: const TextStyle(fontSize: 30)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(frequency.toString(),
                        style: const TextStyle(fontSize: 30)),
                  )
                ],
              );
            } else {
              return const Text("No Data Received");
            }
          }));
    } else {
      return const Text("Not Connected");
    }
  }
}
