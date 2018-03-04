// Step 4: Create an infinite scrolling lazily loaded list

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(new DotstarApp());

class DotstarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Startup Name Generator',
      home: new Dotstar(),
      theme: new ThemeData(primaryColor: Colors.lightGreen),
    );
  }
}

class Current extends StatefulWidget {
  final uri;
  final json;
  Current(this.uri, this.json);
  @override
  State<StatefulWidget> createState() => new CurrentState(uri, json);
}

class CurrentState extends State<Current> {
  final TextStyle _biggerFont = new TextStyle(fontSize: 18.0);
  final Uri uri;
  Map<String, dynamic> json;

  CurrentState(this.uri, this.json);

  @override
  Widget build(BuildContext context) {
    final newRenderer = json["current"]["name"] as String;
    final renderers = json["renderers"] as List<Map<String, dynamic>>;
    final renderer = renderers.firstWhere((e) => e["name"] == newRenderer);
    var jsonProperties = renderer["properties"] as List<Map<String, dynamic>>;
    final properties = ListTile.divideTiles(
        context: context,
        tiles: jsonProperties.map((p) {
          final name = p['name'];
          final type = p['type'];
          final value = p['value'];
          return new ListTile(
            title: new Text(name, style: _biggerFont),
            onTap: () => _doOnTap(name, type, value),
          );
        }));
    return new Scaffold(
      appBar: new AppBar(title: new Text("${renderer['name']}")),
      body: new ListView(children: properties.toList()),
    );
  }

  _doOnTap(String name, String type, dynamic value) {
    switch (type) {
      case "boolean":
        _toggle(name, value as bool);
        break;
      default:
        print("nyi");
        break;
    }
  }

  _toggle(String name, bool value) async {
    var response = (await http.put(uri.resolve("set"),
        headers: {"Content-Type": "application/json"},
        body: JSON.encode({"data" : {name: !value}})));
    final jsonString = response.body;
    final newJson = JSON.decode(jsonString);
    setState(() {
      json = newJson;
    });
  }
}

class Dotstar extends StatefulWidget {
  @override
  createState() =>
      new DotstarState(Uri.parse("http://192.168.0.181:4567/api/"));
}

class DotstarState extends State<Dotstar> {
  final Uri uri;
  Map _fromServer;

  String _errorMessage;

  DotstarState(this.uri);

  @override
  initState() {
    super.initState();
    _index();
  }

  void _index() async {
    var url = uri.resolve("state");
    final response = http.get(url);
    final jsonString = (await response).body;
    final json = JSON.decode(jsonString);
    setState(() => _fromServer = json);
  }

  void _activate(currentName) async {
    var url = uri.resolve("activate");
    final response = http.post(url,
        headers: {"Content-Type": "application/json"},
        body: JSON.encode({"renderer": currentName}));
    final jsonString = (await response).body;
    final json = JSON.decode(jsonString);
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new Current(uri, json);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: _appbar()), body: _progressOrContent());
  }

  Widget _appbar() {
    return new Text("Dotstar@" + uri.toString());
  }

  final TextStyle _biggerFont = new TextStyle(fontSize: 18.0);

  Widget _progressOrContent() {
    if (_fromServer != null) {
      final renderers = (_fromServer["renderers"] as List<Map<String, dynamic>>)
          .map((r) => r["name"] as String)
          .map((name) =>
      new ListTile(
          title: new Text(name, style: _biggerFont),
          onTap: () {
            _activate(name);
          }));
      final currentName = _fromServer["current"]["name"];
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

    if (_errorMessage != null) {
      return new Column(children: <Widget>[
        new Text(_errorMessage),
        new IconButton(icon: new Icon(Icons.redo), onPressed: _index)
      ]);
    }

    return new Center(child: new CircularProgressIndicator());
  }
}
