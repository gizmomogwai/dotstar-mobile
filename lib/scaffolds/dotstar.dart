import 'dart:async';
import 'dart:convert';

import 'package:dotstar/models/server_result.dart';
import 'package:dotstar/scaffolds/current.dart';
import 'package:dotstar/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:mdns/mdns.dart';

class Dotstar extends StatefulWidget {
  @override
  State createState() => new DotstarState();
}

class DotstarState extends State<Dotstar> {
  ServerResult _serverResult;
  ServiceInfo _info;
  Mdns _mdns;
  final Map<String, ServiceInfo> _servers = {};

  DotstarState();

  @override
  void initState() {
    super.initState();
    _serverResult = new ServerResult();
    _mdns = new Mdns();
    final discoveryCallbacks = new DiscoveryCallbacks(
      onDiscovered: (serviceInfo) {},
      onDiscoveryStarted: () {},
      onDiscoveryStopped: () {},
      onResolved: (ServiceInfo info) {
        print('Resolved Service ${info.toString()}');
        setState(() {
          _servers[info.name] = info;
        });
      },
      onLost: (ServiceInfo info) {
        print('Lost $info');
        setState(() => _servers.remove(info.name));
      },
    );

    _mdns = new Mdns(discoveryCallbacks: discoveryCallbacks)
        .startDiscovery('_dotstar._tcp');
    loadServiceInfo().then((ServiceInfo i) {
      _setServiceInfo(i);
    }).catchError((Exception e) => print(e));

  }

  @override
  void dispose() {
    _mdns.stopDiscovery();
    super.dispose();
  }

  void _setServiceInfo(ServiceInfo i) {
    setState(() {
      if (infoToUri(i) != infoToUri(_info)) {
        _info = i;
        print(_info.name);
        print(_info.host);
        print(_info.port);
        storeServiceInfo(_info);
        index();
      }
    });
  }

  Future<void> index() async {
    try {
      if (_info != null) {
        print('getting index');
        setState(() => _serverResult = new ServerResult());
        final url = infoToUri(_info).resolve('api/state');
        final stopwatch = new Stopwatch()..start();
        final response = await get(url).timeout(const Duration(seconds: 15));
        print('getting in ${stopwatch.elapsed} ${stopwatch.elapsed}');
        stopwatch.reset();
        final jsonString = response.body;
        print('got answer $jsonString in ${stopwatch.elapsed}');
        final Map<String, dynamic> json = JSON.decode(jsonString);
        setState(() => _serverResult = new ServerResult(data: json));
      } else {
        print('not getting index, because info is null');
      }
    } on Exception catch (e) {
      setState(() {
        print(e);
        _serverResult = new ServerResult(error: e);
      });
    }
  }

  void showErrorSnack(BuildContext c, Exception e) async {
    Scaffold.of(c).showSnackBar(new SnackBar(
        content: new Text(
          e.toString(),
        ),
        duration: const Duration(days: 1),
        action: new SnackBarAction(
          label: 'Retry',
          onPressed: index,
        )));
  }

  Future<void> _activate(String currentName) async {
    try {
      setState(() => _serverResult = new ServerResult());
      final url = infoToUri(_info).resolve('api/activate');
      final response = await post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: JSON.encode({'renderer': currentName}),
      );
      final jsonString = response.body;
      final Map<String, dynamic> json = JSON.decode(jsonString);
      await Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) {
          return new Current(_info, new ServerResult(data: json));
        },
      ));
      index();
    } on Exception catch (e) {
      setState(() => _serverResult = new ServerResult(error: e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> servers = []
      ..add(
        const DrawerHeader(
          child: const DecoratedBox(
            decoration: const BoxDecoration(
                image: const DecorationImage(
                    image: const AssetImage('assets/strip.jpg'))),
          ),
        ),
      )
      ..addAll(_servers.keys.map((name) => new ListTile(
            title: new Text(name, style: biggerFont()),
            onTap: () {
              print('setting service ${_servers[name].name}');
              _setServiceInfo(_servers[name]);
              Navigator.of(context).pop();
            },
          )))
      ..add(const AboutListTile());

    return new Scaffold(
      appBar: new AppBar(title: _appbar()),
      body: new Builder(
        builder: _progressOrContent,
      ),
      drawer: new Drawer(
        child: new ListView(
          children: servers,
        ),
      ),
    );
  }

  Widget _appbar() {
    if (_info == null) {
      return const Text('Please select dotstar server');
    } else {
      return new Text('${_info.name}${_info.host}:${_info.port}');
    }
  }

  Widget _progressOrContent(BuildContext context) {
    if (_serverResult.error != null) {
      showErrorSnack(context, _serverResult.error);
      return new Container(
        width: 0.0,
        height: 0.0,
      );
    }

    if (_serverResult.data != null) {
      final renderers =
          (_serverResult.data['renderers'] as List<Map<String, dynamic>>)
              .map((r) => r['name'] as String)
              .map((name) => new ListTile(
                  title: new Text(name, style: biggerFont()),
                  onTap: () {
                    _activate(name);
                  }));
      final String currentName = _serverResult.data['current']['name'];
      final current = new ListTile(
        title: new Text('current - $currentName', style: biggerFont()),
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
