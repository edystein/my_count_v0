// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void dataframeWithHeaderDemo() {
  // final data = [
  //   ['Event', 'Amount', 'Date'],
  //   ['Sweet', .5, DateTime.now()],
  //   ['Sweet', 1, DateTime.now()],
  //   ['Sweet', .5, DateTime.now()],
  //   ['Sweet', 1.5, DateTime.now()],
  // ];
  var data = [
    ['Event', 'Amount', 'Date'],
    ['Sweet', 0, DateTime.now().millisecondsSinceEpoch],
    ['Sweet', 1.5, DateTime.now().millisecondsSinceEpoch]
  ];
  final df = DataFrame(data);
  final df_json = df.toJson();
  final df2 = DataFrame.fromJson(json.decode(json.encode(df_json)));

  print("${df['Amount']}");
  print("${df['Amount'].data.reduce((a, b) => a + b)}");
  final rows = df.rows;
  print('rows: $rows');
}

void main() {
  // dataframeWithHeaderDemo();

  runApp(
    MaterialApp(
      title: 'Reading and Writing Files',
      home: HomePage(storage: CounterStorage()),
    ),
  );
}

class CounterStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/raw_data.txt');
  }

  Future<DataFrame> readCounter() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();
      print('contents: $contents');
      final df = DataFrame.fromJson(json.decode(contents));
      print('Read Counter');
      print('df:\n{$df}\n\n*******************');
      return df;
    } catch (e) {
      // If encountering an error, return 0
      var rawData = [
        ['Event', 'Amount', 'Date'],
        ['Sweet', 0, DateTime.now().millisecondsSinceEpoch],
      ];
      final df = DataFrame(rawData);
      return df;
    }
  }

  Future<File> writeCounter(int counter, DataFrame df) async {
    final file = await _localFile;

    print('Write Counter');
    print('df:\n{$df}\n\n*******************');

    // Write the file
    var dfSerialized = json.encode(df.toJson());
    return file.writeAsString(dfSerialized);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage});

  final CounterStorage storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  var df = DataFrame([
    ['Event', 'Amount', 'Date'],
    ['Sweet-raw', 0, DateTime.now().millisecondsSinceEpoch]
  ]);

  @override
  void initState() {
    super.initState();
    widget.storage.readCounter().then((value) {
      setState(() {
        print('\t\t-----inistState');
        df = value;
        print('$df');
        _counter = df['Amount'].data.reduce((a, b) => a + b);
        print('df[Amount]: ${df['Amount']}');
        print('_counter: $_counter');
      });
    });
  }

  Future<File> _incrementCounter() {
    print('_incrementCounter');
    setState(() {
      _counter++;
      var newData = ['Sweet', 1, DateTime.now().millisecondsSinceEpoch];
      var df_json = df.toJson();
      var l_data = df_json['R'];
      l_data.insert(l_data.length, newData);
      df_json['R'] = l_data;
      df = DataFrame.fromJson(df_json);
      print('df: $df');
    });

    // Write the variable as a string to the file.
    return widget.storage.writeCounter(_counter, df);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading and Writing Files'),
      ),
      body: Center(
          child: Container(
              child: Column(children: [
        Text(
            'Button tapped $_counter time${_counter == 1 ? '' : 's'}. \n\nDEBUG\n'),
        SfCartesianChart(
          title: ChartTitle(text: 'Sweet vs. Day Of Week'),
          legend: Legend(isVisible: true),
          series: <ChartSeries>[
            BarSeries<AggData, String>(
                name: 'Day of week',
                dataSource: getCountData(df = df),
                xValueMapper: (AggData e, _) => e.period,
                yValueMapper: (AggData e, _) => e.val,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                dataLabelSettings: DataLabelSettings(isVisible: true),
                enableTooltip: true)
          ],
          primaryXAxis: CategoryAxis(),
          primaryYAxis: NumericAxis(),
        ),
      ]))),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<AggData> getDOWData() {
    print('-----getDOWData--------');
    print('$df');
    print('Finish -----getDOWData--------');

    final List<AggData> chartData = [
      AggData('Oceania', 1600),
      AggData('Africa', 2490),
      AggData('S America', 2900),
      AggData('Europe', 23050),
      AggData('N America', 24880),
      AggData('Asia', 34390),
    ];
    return chartData;
  }
}

class AggData {
  final String period;
  final int val;
  AggData(this.period, this.val);
}

getDOWFromMilliEpoch(milliepoch) {
  var date = DateTime.fromMillisecondsSinceEpoch(milliepoch);
  String dayOfWeek = date.weekday == 7
      ? 'Sunday'
      : date.weekday == 1
          ? 'Monday'
          : date.weekday == 2
              ? 'Tuesday'
              : date.weekday == 3
                  ? 'Wednesday'
                  : date.weekday == 4
                      ? 'Thursday'
                      : date.weekday == 5
                          ? 'Friday'
                          : date.weekday == 6
                              ? 'Saturday'
                              : '';
  return dayOfWeek;
}

List<AggData> getDOWCount(list) {
  Map<String, int> countMap = {
    'Saturday': 0,
    'Friday': 0,
    'Thursday': 0,
    'Wednesday': 0,
    'Tuesday': 0,
    'Monday': 0,
    'Sunday': 0
  };
  try {
    for (String item in list) {
      countMap[item] = (countMap[item] ?? 0) + 1;
    }
  } catch (e) {
    print(e);
    countMap[list] = 1;
  }

  List<AggData> lDOW =
      countMap.entries.map((e) => AggData(e.key, e.value)).toList();

  return lDOW;
}

List<AggData> getCountData(df,
    [int nDays = 30, String event = 'Sweet', String aggType = 'dow']) {
  DateTime now = DateTime.now();

  // filter by event type
  final events = df['Event'].data.toList();
  List<int> lIndex = [];
  for (var i = 0; i < events.length; i++) {
    if (events[i] == event) {
      lIndex.add(i);
    }
  }

  List<AggData> res = [AggData('wow', 7)];
  if (lIndex.isEmpty) {
    return res;
  }
  var dfFilt;
  if (lIndex.length == events.length) {
    dfFilt = df;
  } else {
    dfFilt = df.sampleFromRows(lIndex);
  }

  // filter by date
  var eventType = 'Sweet';
  lIndex = [];
  final lDates = df['Date'].data.toList();
  final lEvents = df['Event'].data.toList();
  final lAmount = df['Amount'].data.toList();

  for (var i = 0; i < lDates.length; i++) {
    if ((now.difference(DateTime.fromMillisecondsSinceEpoch(lDates[i])).inDays <
            nDays) &&
        (lEvents[i] == eventType) &&
        (lAmount[i] > 0)) {
      lIndex.add(i);
    }
  }
  if (lIndex.isEmpty) {
    return res;
  }

  if (lIndex.length != lDates.length) {
    dfFilt = df.sampleFromRows(lIndex);
  }

  // category filter
  if (aggType == 'dow') {
    res = getDOWCount(dfFilt['Date'].data.map((a) => getDOWFromMilliEpoch(a)));
  }
  return res;
}
