import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mdns/mdns.dart';

class ProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new LinearProgressIndicator(value: null);
  }
}

Uri infoToUri(ServiceInfo i) {
  final newUri = Uri.parse("http:/${i.host}:${i.port}");
  return newUri;
}
