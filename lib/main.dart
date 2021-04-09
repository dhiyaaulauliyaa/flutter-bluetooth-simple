import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;

  StreamSubscription<bool> _scanStatus;
  bool _isScanning;

  StreamSubscription<List<int>> _listener;
  bool _isListening;

  String _val1 = '??';
  String _val2 = '??';

  final _writeController = TextEditingController();

  /* Add bluetooth device(s) to list */
  void _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
        print(device.name);
      });
    }
  }

  void _startScanning() async {
    /* Remove previous connected device */
    _connectedDevice = null;

    /* Add already known device to ble devices list */
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });

    /* Add new device(s) from scan result to ble devices list */
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });

    /* Scan for new ble device(s) */
    widget.flutterBlue.startScan();
  }

  void _connectToDevice(BluetoothDevice device) async {
    widget.flutterBlue.stopScan();
    try {
      await device.connect();
    } catch (e) {
      if (e.code != 'already_connected') {
        throw e;
      }
    } finally {
      _services = await device.discoverServices();
    }
    _connectedDevice = device;

    setState(() {});
  }

  void _readFromDevice(BluetoothCharacteristic characteristic) async {
    List<int> value = await characteristic.read();
    String parsed = String.fromCharCodes(value);
    print(parsed);
    // setState(() {
    //   widget.readValues[characteristic.uuid] = value;
    // });
  }

  void _writeToDevice(BluetoothCharacteristic characteristic) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Write"),
          content: TextField(controller: _writeController),
          actions: <Widget>[
            TextButton(
              child: Text("Send"),
              onPressed: () {
                characteristic.write(
                  utf8.encode(_writeController.value.text),
                  withoutResponse: true,
                );
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _getNotifierFromDevice(BluetoothCharacteristic characteristic) async {
    /* Bluetooth notifying toggle */
    await characteristic.setNotifyValue(!characteristic.isNotifying);
    setState(() {
      _isListening = characteristic.isNotifying;
    });

    /* Update the value */
    if (_isListening) {
      _listener = characteristic.value.listen((value) {
        setState(() {
          widget.readValues[characteristic.uuid] = value;
        });
      });
    }

    /* Stop listening */
    else
      _listener.cancel();
  }

  _dataParser(String data) {
    print('parser');
    if (data.isNotEmpty) {
      var data1 = data.split(",")[0];
      var data2 = data.split(",")[1];

      setState(() {
        _val1 = data1;
        _val2 = data2;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _isScanning = false;
    _isListening = false;

    _scanStatus = widget.flutterBlue.isScanning.listen((event) {
      setState(() {
        _isScanning = event;
        print(event);
        print('isScan $_isScanning');
      });
    });

    _startScanning();
  }

  @override
  void dispose() {
    _scanStatus.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /* BLE Device(s) list builder */
    SliverList _bleDevicesList() {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            String deviceName = widget.devicesList[index].name;
            return ListTile(
              title: Text(deviceName == '' ? 'Unknown Device' : deviceName),
              trailing: ElevatedButton(
                child: Text('Connect'),
                onPressed: () {
                  _connectToDevice(widget.devicesList[index]);
                },
              ),
            );
          },
          childCount: widget.devicesList.length,
        ),
      );
    }

    /* Button for Write, Read, or Notify */
    List<TextButton> _characteristicsAction(
        BluetoothCharacteristic characteristic) {
      List<TextButton> buttons = <TextButton>[];

      if (characteristic.properties.read) {
        buttons.add(
          TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
                backgroundColor: MaterialStateProperty.all(Colors.black54),
                ),
            child: Text('Read'),
            onPressed:
                _isListening ? null : () => _readFromDevice(characteristic),
          ),
        );
      }
      if (characteristic.properties.write) {
        buttons.add(
          TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
                backgroundColor: MaterialStateProperty.all(Colors.black54),
                ),
            child: Text('Write'),
            // onPressed: () => _writeToDevice(characteristic),
            onPressed: () {
              String ssid = 'randomssid';
              String pass = 'test123456';
              String text = '$ssid, $pass';

              print('Printing $text');

              characteristic.write(
                utf8.encode(text),
                withoutResponse: false,
              );
            },
          ),
        );
      }
      if (characteristic.properties.notify) {
        buttons.add(
          TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
                backgroundColor: MaterialStateProperty.all(Colors.black54),
                ),
            child: Text(_isListening ? 'Stop Notifying' : 'Notify'),
            onPressed: () => _getNotifierFromDevice(characteristic),
          ),
        );
      }

      return buttons;
    }

    /* Connected BLE Device details */
    SliverToBoxAdapter _connectedDeviceWidget() {
      /* Make list for every service */
      List<ExpansionTile> servicesList = <ExpansionTile>[];
      for (BluetoothService service in _services) {
        /* Make list for characteristic in every service */
        List<Column> characteristicsList = <Column>[];
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          String valueReceived =
              widget.readValues[characteristic.uuid].toString();

          if (valueReceived != 'null') {
            print('receive: $valueReceived');
            final decoded = utf8.decode(widget.readValues[characteristic.uuid]);
            _dataParser(decoded);
          }

          characteristicsList.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    characteristic.uuid.toString(),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                valueReceived == 'null'
                    ? SizedBox()
                    : Text(
                        'Value Received: ' + valueReceived,
                      ),
                valueReceived == 'null' ? SizedBox() : Text('Val 1: ' + _val1),
                valueReceived == 'null' ? SizedBox() : Text('Val 2: ' + _val2),
                SizedBox(
                  height: valueReceived == null ? 0 : 8.0,
                ),
                Wrap(
                  spacing: 16.0,
                  children: <Widget>[..._characteristicsAction(characteristic)],
                ),
                service.characteristics.length == 1
                    ? SizedBox(width: MediaQuery.of(context).size.width)
                    : characteristic ==
                            service.characteristics[
                                service.characteristics.length - 1]
                        ? SizedBox(width: MediaQuery.of(context).size.width)
                        : Divider(color: Colors.white30)
              ],
            ),
          );
        }

        /* Add the tiles */
        servicesList.add(
          ExpansionTile(
            title: Text(service.uuid.toString()),
            subtitle: Text('Device Service'),
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child: Column(
                  children: <Widget>[...characteristicsList],
                ),
              )
            ],
          ),
        );
      }

      return SliverToBoxAdapter(
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(_connectedDevice.name),
              subtitle: Text('Device Name'),
            ),
            ...servicesList
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth App'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _isScanning ? () => widget.flutterBlue.stopScan() : _startScanning,
        backgroundColor: _isScanning ? Colors.orangeAccent : Colors.blue,
        child: Icon(_isScanning ? Icons.close : Icons.search),
      ),
      body: Container(
        child: CustomScrollView(
          slivers: <Widget>[
            /* Title */
            SliverToBoxAdapter(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _isScanning
                          ? 'SEARCHING FOR DEVICES'
                          : _connectedDevice != null
                              ? 'DEVICE CONNECTED!'
                              : widget.devicesList.length == 0
                                  ? 'DEVICE NOT FOUND'
                                  : 'SCAN RESULTS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    color: Colors.grey,
                  )
                ],
              ),
            ),
            /* Show List or Device Menu */
            _connectedDevice == null
                ? _bleDevicesList()
                : _connectedDeviceWidget(),
          ],
        ),
      ),
    );
  }
}
