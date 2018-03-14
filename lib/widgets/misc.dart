import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mdns/mdns.dart';
import 'package:path_provider/path_provider.dart';

///
class ProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const LinearProgressIndicator(value: null);
}

///
Uri infoToUri(ServiceInfo i) {
  if (i == null) {
    return null;
  }
  final newUri = Uri.parse('http:/${i.host}:${i.port}');
  return newUri;
}

///
Future<void> storeServiceInfo(ServiceInfo info) async {
  final h = {
    'name': info.name,
    'type': info.type,
    'host': info.host,
    'port': info.port
  };
  final json = JSON.encode(h);
  final dir = (await getApplicationDocumentsDirectory()).path;
  final file = new File('$dir/serviceInfo.json');
  await file.writeAsString(json);
}

/// 
Future<ServiceInfo> loadServiceInfo() async {
  final dir = (await getApplicationDocumentsDirectory()).path;
  final file = new File('$dir/serviceInfo.json');
  final Map<String, dynamic> content = JSON.decode(await file.readAsString());
  return ServiceInfo.fromMap(content);
}

///
String toHex(Color c) {
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
