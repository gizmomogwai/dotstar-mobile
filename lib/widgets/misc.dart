import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mdns/mdns.dart';
import 'package:path_provider/path_provider.dart';

class ProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new LinearProgressIndicator(value: null);
  }
}

Uri infoToUri(ServiceInfo i) {
  if (i == null) {
    return null;
  }
  final newUri = Uri.parse("http:/${i.host}:${i.port}");
  return newUri;
}

Future storeServiceInfo(ServiceInfo info) async {
  final h = {
    "name": info.name,
    "type": info.type,
    "host": info.host,
    "port": info.port
  };
  final json = JSON.encode(h);
  String dir = (await getApplicationDocumentsDirectory()).path;
  final file = new File("$dir/serviceInfo.json");
  file.writeAsString(json);
}

Future<ServiceInfo> loadServiceInfo() async {
  String dir = (await getApplicationDocumentsDirectory()).path;
  final file = new File("$dir/serviceInfo.json");
  final content = JSON.decode(await file.readAsString());
  return ServiceInfo.fromMap(content);
}
