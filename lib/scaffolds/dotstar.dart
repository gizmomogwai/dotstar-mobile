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
  createState() => new DotstarState();
}

class DotstarState extends State<Dotstar> {
  ServerResult _serverResult;

  Mdns _mdns;
  final _servers = new Map<String, ServiceInfo>();

  ServiceInfo _info;

  DotstarState();

  @override
  initState() {
    super.initState();
    _serverResult = new ServerResult();

    final discoveryCallbacks = new DiscoveryCallbacks(
      onDiscovered: (ServiceInfo) {},
      onDiscoveryStarted: () {},
      onDiscoveryStopped: () {},
      onResolved: (ServiceInfo info) {
        print("Resolved Service ${info.toString()}");
        setState(() {
          _servers[info.name] = info;
        });
      },
    );

    _mdns = new Mdns(discoveryCallbacks: discoveryCallbacks);
    _mdns.startDiscovery("_dotstar._tcp");

    loadServiceInfo().then((ServiceInfo i) {
      _setServiceInfo(i);
      index();
    });
  }

  _setServiceInfo(ServiceInfo i) {
    setState(() {
      if (infoToUri(i) != infoToUri(_info)) {
        _info = i;
        storeServiceInfo(_info);
        index();
      }
    });
  }

  void index() async {
    try {
      if (_info != null) {
        print("getting index");
        setState(() => _serverResult = new ServerResult());
        var url = infoToUri(_info).resolve("api/state");
        final response = get(url).timeout(const Duration(seconds: 5));
        final jsonString = (await response).body;
        final json = JSON.decode(jsonString);
        setState(() => _serverResult = new ServerResult(data: json));
      }
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
      var url = infoToUri(_info).resolve("api/activate");
      final response = post(
        url,
        headers: {"Content-Type": "application/json"},
        body: JSON.encode({"renderer": currentName}),
      );
      final jsonString = (await response).body;
      final json = JSON.decode(jsonString);
      (await Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) {
          return new Current(_info, new ServerResult(data: json));
        },
      )));
      index();
    } catch (e) {
      setState(() => _serverResult = new ServerResult(error: e));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> servers = []
      ..add(
        new DrawerHeader(
          child: new DecoratedBox(
            decoration: new BoxDecoration(
                image: new DecorationImage(
                    image: new AssetImage("assets/strip.jpg"))),
          ),
        ),
      )
      ..addAll(_servers.keys.map((name) {
        return new ListTile(
          title: new Text(name),
          onTap: () {
            _setServiceInfo(_servers[name]);
            Navigator.of(context).pop();
          },
        );
      }))
      ..add(new AboutListTile());

    return new Scaffold(
      appBar: new AppBar(title: _appbar()),
      body: new Builder(
        builder: (BuildContext c) {
          return _progressOrContent(c);
        },
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
      return new Text("Please select dotstar server");
    } else {
      return new Text("${_info.name}${_info.host}:${_info.port}");
    }
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
