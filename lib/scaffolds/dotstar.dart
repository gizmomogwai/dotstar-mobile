import 'dart:convert';

import 'package:dotstar/models/server_result.dart';
import 'package:dotstar/scaffolds/current.dart';
import 'package:dotstar/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

class Dotstar extends StatefulWidget {
  @override
  createState() =>
      new DotstarState(Uri.parse("http://192.168.0.181:4567/api/"));
}

class DotstarState extends State<Dotstar> {
  final Uri uri;
  ServerResult _serverResult;

  DotstarState(this.uri);

  @override
  initState() {
    super.initState();
    _serverResult = new ServerResult();
    index();
  }

  void index() async {
    try {
      print("getting index");
      setState(() => _serverResult = new ServerResult());
      var url = uri.resolve("state");
      final response = get(url).timeout(const Duration(seconds: 5));
      final jsonString = (await response).body;
      final json = JSON.decode(jsonString);
      setState(() => _serverResult = new ServerResult(data: json));
    } catch (e) {
      setState(() {
        _serverResult = new ServerResult(error: e);
      });
    }
  }

  void showErrorSnack(BuildContext c, e) {
    Scaffold.of(c).showSnackBar(new SnackBar(
        content: new Text(
          e.toString(),
        ),
        duration: new Duration(days: 1),
        action: new SnackBarAction(
          label: "Retry",
          onPressed: () {
            index();
          },
        )));
  }

  void _activate(currentName) async {
    try {
      setState(() => _serverResult = new ServerResult());
      var url = uri.resolve("activate");
      final response = post(
        url,
        headers: {"Content-Type": "application/json"},
        body: JSON.encode({"renderer": currentName}),
      );
      final jsonString = (await response).body;
      final json = JSON.decode(jsonString);
      ServerResult res = (await Navigator
          .of(context)
          .push(new MaterialPageRoute(builder: (context) {
        return new Current(uri, new ServerResult(data: json));
      })));
      if (res == null) {
        index();
      }
      if (res.error != null) {
        throw res.error;
      }
      setState(() => _serverResult = res);
    } catch (e) {
      setState(() => _serverResult = new ServerResult(error: e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: _appbar()),
        body: new Builder(
          builder: (BuildContext c) {
            return _progressOrContent(c);
          },
        ));
  }

  Widget _appbar() {
    return new Text("Dotstar@" + uri.toString());
  }

  final TextStyle _biggerFont = new TextStyle(fontSize: 18.0);

  _progressOrContent(BuildContext context) {
    if (_serverResult.error != null) {
      try {
        showErrorSnack(context, _serverResult.error);
      } catch (e) {
        print(e);
      }
      return new Text("error: " + _serverResult.error.toString());
    }

    if (_serverResult.data != null) {
      final renderers =
          (_serverResult.data["renderers"] as List<Map<String, dynamic>>)
              .map((r) => r["name"] as String)
              .map((name) => new ListTile(
                  title: new Text(name, style: _biggerFont),
                  onTap: () {
                    _activate(name);
                  }));
      final currentName = _serverResult.data["current"]["name"];
      final current = new ListTile(
        title: new Text("current - " + currentName, style: _biggerFont),
        onTap: () {
          _activate(currentName);
        },
      );
      return new ListView(
          children: []
            ..add(current)
            ..addAll(renderers));
    }

    return new ProgressWidget();
  }
}
