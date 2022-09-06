import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<String>> _logs;

  @override
  void initState() {
    super.initState();
    _logs = getLogs();
  }

  Future<List<String>> getLogs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var logsPrefs = prefs.getStringList('logs');
    List<String> newLogs = List.empty(growable: true);
    if (logsPrefs != null && logsPrefs.isNotEmpty) {
      newLogs = logsPrefs;
    } else {
      newLogs = List.empty(growable: true);
    }
    return newLogs;
  }

  ListView generateLogs(List<String> logs) {
    List<Container> texts = logs
        .map(
          (log) => Container(
            margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            child: Text(log),
          ),
        )
        .toList();
    return ListView(children: [...texts]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.only(top: 50),
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/unknown.png'), fit: BoxFit.cover)),
      child: FutureBuilder<List<String>>(
        future: _logs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            return generateLogs(snapshot.data!);
          }

          return CircularProgressIndicator(
            color: Colors.red.shade500,
          );
        },
      ),
    ));
  }
}
