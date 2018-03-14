import 'package:dotstar/scaffolds/dotstar.dart';
import 'package:flutter/material.dart';

void main() => runApp(new DotstarApp());

class DotstarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new MaterialApp(
        title: 'Dotstar',
        home: new Dotstar(),
      );
}
