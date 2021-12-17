import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:control_center/page.dart';
import 'package:dbus/dbus.dart';

class NouveauSettingsPage extends SettingsPage {
  const NouveauSettingsPage(
      {Key? key, required String title, required DBusClient client})
      : super(key: key, title: title, client: client);

  @override
  Widget buildPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          NouveauSettings(
              client: client,
              showDBusError: (text) => showDBusError(context, text)),
        ],
      ),
    );
  }
}

class NouveauSettings extends StatefulWidget {
  const NouveauSettings(
      {Key? key, required this.client, required this.showDBusError})
      : super(key: key);

  final DBusClient client;
  final Future<void> Function(List<Widget>) showDBusError;

  @override
  createState() => _NouveauSettingsState();
}

class _NouveauSettingsState extends State<NouveauSettings> {
  List<num> driDevices = [];
  late Timer _timer;

  Future<void> updateStateFromDBus() async {
    var object = DBusRemoteObject(widget.client,
        name: 'com.retrixe.ControlCenter.v0',
        path: DBusObjectPath('/com/retrixe/ControlCenter/v0'));
    var result = await object
        .callMethod('com.retrixe.ControlCenter.v0', 'NouveauGetDRIDevices', []);
    var values = List<int>.from(result.values[0].toNative());
    setState(() => driDevices = values);
  }

  @override
  void initState() {
    super.initState();
    updateStateFromDBus().catchError((error) {
      stderr.writeln(error);
      widget.showDBusError(const [
        Text("An error occurred when talking to the Control Center daemon."),
        Text("The app WILL not work correctly!"),
      ]);
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await updateStateFromDBus();
      } catch (error) {
        stderr.writeln(error);
        widget.showDBusError(const [
          Text("An error occurred when talking to the Control Center daemon."),
          Text("The app WILL not work correctly!"),
        ]);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: driDevices.isNotEmpty
            ? driDevices
                .map((device) => NouveauDriDevice(
                      client: widget.client,
                      showDBusError: widget.showDBusError,
                      driDevice: device,
                    ))
                .toList()
            : const [Text("No devices with nouveau detected!")],
      ),
    );
  }
}

class NouveauDriDevice extends StatefulWidget {
  const NouveauDriDevice(
      {Key? key,
      required this.driDevice,
      required this.client,
      required this.showDBusError})
      : super(key: key);

  final num driDevice;
  final DBusClient client;
  final Future<void> Function(List<Widget>) showDBusError;

  @override
  createState() => _NouveauDriDeviceState();
}

class _NouveauDriDeviceState extends State<NouveauDriDevice> {
  // List<num> driDevices = [];
  late Timer _timer;

  Future<void> updateStateFromDBus() async {
    /* var object = DBusRemoteObject(widget.client,
        name: 'com.retrixe.ControlCenter.v0',
        path: DBusObjectPath('/com/retrixe/ControlCenter/v0'));
    var result = await object
        .callMethod('com.retrixe.ControlCenter.v0', 'NouveauGetPowerStates', []);
    var values = List<int>.from(result.values[0].toNative());
    setState(() => driDevices = values); */
  }

  @override
  void initState() {
    super.initState();
    updateStateFromDBus().catchError((error) {
      stderr.writeln(error);
      widget.showDBusError(const [
        Text("An error occurred when talking to the Control Center daemon."),
        Text("The app WILL not work correctly!"),
      ]);
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await updateStateFromDBus();
      } catch (error) {
        stderr.writeln(error);
        widget.showDBusError(const [
          Text("An error occurred when talking to the Control Center daemon."),
          Text("The app WILL not work correctly!"),
        ]);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        child: Column(children: [
          Text("nouveau DRI device ${widget.driDevice} (N/A)",
              style: Theme.of(context).textTheme.headline6),
          const Divider(),
          const Text("pstate toggling not yet implemented"),
        ]),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
