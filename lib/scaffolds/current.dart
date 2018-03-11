import 'dart:convert';

import 'package:dotstar/models/server_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;

import '../widgets/misc.dart';

class Current extends StatefulWidget {
  final uri;
  final serverResult;

  Current(this.uri, this.serverResult);

  @override
  State<StatefulWidget> createState() => new CurrentState(uri, serverResult);
}

class CurrentState extends State<Current> {
  final TextStyle _biggerFont = new TextStyle(fontSize: 18.0);
  final Uri uri;
  var serverResult;

  CurrentState(this.uri, this.serverResult);

  @override
  Widget build(BuildContext context) {
    if (serverResult.data != null) {
      final json = serverResult.data;
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

    return new Scaffold(
      appBar: new AppBar(title: new Text("...")),
      body: new ProgressWidget(),
    );
  }

  _doOnTap(String name, String type, dynamic value) {
    switch (type) {
      case "boolean":
        _toggle(name, value as bool);
        break;
      case "color":
        showDialog(
          context: context,
          child: new AlertDialog(
            title: new Text(name),
            content: new SingleChildScrollView(
              child: new ColorPicker(
                pickerColor: new Color(int
                    .parse((value as String).replaceFirst("#", ""), radix: 16)),
                onColorChanged: (Color c) {
                  var v = "${_toHex(c)}";
                  _set(name, v);
                },
                enableLabel: false,
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                  child: new Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ],
          ),
        );
        break;
      default:
        print("nyi");
        break;
    }
  }

  _set(String name, String value) async {
    try {
      setState(() => serverResult = new ServerResult());
      var response = (await http.put(
        uri.resolve("set"),
        headers: {"Content-Type": "application/json"},
        body: JSON.encode({
          "data": {name: value}
        }),
      ));
      final jsonString = response.body;
      final newJson = JSON.decode(jsonString);
      setState(() {
        serverResult = new ServerResult(data: newJson);
      });
    } catch (e) {
      print("back to track");
      Navigator.of(context).pop(new ServerResult(error: e));
    }
  }

  _toggle(String name, bool value) async {
    _set(name, "${!value}");
  }

  _toHex(Color c) {
    var r = _toHexComponent(c.red);
    var g = _toHexComponent(c.green);
    var b = _toHexComponent(c.blue);
    return "#$r$g$b";
  }
  
  _toHexComponent(int v) {
    var res = v.toRadixString(16);
    if (res.length < 2) {
      return "0$res";
    }
    return res;
  }
}
