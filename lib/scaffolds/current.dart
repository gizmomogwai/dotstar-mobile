import 'dart:async';
import 'dart:convert';

import 'package:dotstar/models/server_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:mdns/mdns.dart';

import '../widgets/misc.dart';

class Current extends StatefulWidget {
  final ServiceInfo info;
  final ServerResult serverResult;

  Current(this.info, this.serverResult);

  @override
  State<StatefulWidget> createState() => new CurrentState(info, serverResult);
}

class CurrentState extends State<Current> {
  final ServiceInfo info;
  ServerResult serverResult;

  CurrentState(this.info, this.serverResult);

  @override
  Widget build(BuildContext context) {
    if (serverResult.data != null) {
      final json = serverResult.data;
      final newRenderer = json['current']['name'] as String;
      final renderers = json['renderers'] as List<Map<String, dynamic>>;
      final renderer = renderers.firstWhere((e) => e['name'] == newRenderer);
      var jsonProperties = renderer['properties'] as List<Map<String, dynamic>>;
      final properties = ListTile.divideTiles(
          context: context,
          tiles: jsonProperties.map((p) {
            final String name = p['name'];
            final String type = p['type'];
            final dynamic value = p['value'];
            final dynamic min = p['min'];
            final dynamic max = p['max'];
            return new ListTile(
              title: new Text(name, style: biggerFont()),
              subtitle: createSubtitle(p, type, value, min, max),
            );
          }));
      return new Scaffold(
        appBar: new AppBar(title: new Text('${renderer['name']}')),
        body: new ListView(children: properties.toList()),
      );
    }

    return new Scaffold(
      appBar: new AppBar(title: const Text('...')),
      body: new ProgressWidget(),
    );
  }

  Future<void> _set(String name, String value) async {
    try {
      var response = (await http.put(
        infoToUri(info).resolve('api/set'),
        headers: {'Content-Type': 'application/json'},
        body: JSON.encode({
          'data': {name: value}
        }),
      ));
      final jsonString = response.body;
      final Map<String, dynamic> newJson = JSON.decode(jsonString);
      setState(() {
        serverResult = new ServerResult(data: newJson);
      });
    } on Exception {
      print('back to track');
      Navigator.of(context).pop();
    }
  }

  String _toHex(Color c) {
    final r = _toHexComponent(c.red);
    final g = _toHexComponent(c.green);
    final b = _toHexComponent(c.blue);
    return '#$r$g$b';
  }

  String _toHexComponent(int v) {
    final res = v.toRadixString(16);
    if (res.length < 2) {
      return '0$res';
    }
    return res;
  }

  Widget createSubtitle(Map<String, dynamic> property, String type,
      dynamic value, dynamic min, dynamic max) {
    String name = property['name'];
    switch (type) {
      case 'float':
        return new Slider(
          value: (value as num).toDouble(),
          min: (min as num).toDouble(),
          max: (max as num).toDouble(),
          onChanged: (value) {
            setState(() {
              _set(name, '$value');
              property['value'] = value;
            });
          },
        );
      case 'boolean':
        return new Checkbox(
            value: (value as bool),
            onChanged: (v) {
              _set(name, '$v');
            });
      case 'color':
        final color = new Color(
            int.parse((value as String).replaceFirst('#', 'ff'), radix: 16));
        return new Container(
            child: new RaisedButton(
                child: new Text('$value', style: biggerFont()),
                color: color,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    child: new AlertDialog(
                      title: new Text(name),
                      content: new SingleChildScrollView(
                        child: new ColorPicker(
                          pickerColor: color,
                          onColorChanged: (Color c) {
                            var v = '${_toHex(c)}';
                            _set(name, v);
                          },
                          enableLabel: false,
                        ),
                      ),
                      actions: <Widget>[
                        new FlatButton(
                            child: new Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            })
                      ],
                    ),
                  );
                }));
      default:
        return new Text('nyi for $type');
    }
  }
}
