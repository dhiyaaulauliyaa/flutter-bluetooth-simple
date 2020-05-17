import 'dart:async';
import 'dart:convert' show utf8;

import 'package:bluetooth_app/provider/Account.dart';
import 'package:bluetooth_app/screens/account/AccountPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccountProvider>.value(
          value: AccountProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bluetooth',
        theme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String charUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  String _myDeviceId;
  String _val1 = '??';
  String _val2 = '??';

  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;
  BluetoothCharacteristic _characteristic;
  List<int> _valueReceived;

  StreamSubscription<bool> _scanStatus;
  bool _isScanning;

  StreamSubscription<List<int>> _listener;
  bool _isListening;

  final _writeController = TextEditingController();

  /* Add bluetooth device(s) to list */
  void _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
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

        /* Implementing auto connect to device */
        _autoConnectToDevice(_myDeviceId, device);
      }
    });

    /* Add new device(s) from scan result to ble devices list */
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);

        /* Implementing auto connect to device */
        _autoConnectToDevice(_myDeviceId, result.device);
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

    print("Device ID: ${device.id.toString()}");
    print("Device Name: ${device.name}");

    /* Recognizing device first by checking its characteristic */
    bool authorized = false;
    for (BluetoothService service in _services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == charUUID) {
          print('Device known');
          authorized = true;
          setState(() {
            _characteristic = characteristic;
          });
        }
      }
    }

    if (authorized) {
      _connectedDevice = device;
      _getNotifierFromDevice(_characteristic);
    } else {
      /* Bluetooth device unknown */
      print('device unknwn');
    }

    setState(() {});
  }

  void _autoConnectToDevice(String id, BluetoothDevice device) {
    if (id == device.id.toString()) {
      _connectToDevice(device);
    }
  }

  void _readFromDevice(BluetoothCharacteristic characteristic) async {
    /* Read value */
    List<int> value = await characteristic.read();

    setState(() {
      widget.readValues[characteristic.uuid] = value;
    });
  }

  void _writeToDevice(BluetoothCharacteristic characteristic) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Write"),
          content: TextField(controller: _writeController),
          actions: <Widget>[
            FlatButton(
              child: Text("Send"),
              onPressed: () {
                characteristic.write(
                  utf8.encode(_writeController.value.text),
                  withoutResponse: true,
                );
                Navigator.pop(context);
              },
            ),
            FlatButton(
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
    print('enable notifier');

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
          _valueReceived = value;
    print('update value');

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

    // _startScanning();
    // _loadDeviceID();
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
              trailing: RaisedButton(
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
    List<FlatButton> _characteristicsAction(
        BluetoothCharacteristic characteristic) {
      List<FlatButton> buttons = new List<FlatButton>();

      if (characteristic.properties.read) {
        buttons.add(
          FlatButton(
            color: Colors.white10,
            child: Text('Read'),
            onPressed:
                _isListening ? null : () => _readFromDevice(characteristic),
          ),
        );
      }
      if (characteristic.properties.write) {
        buttons.add(
          FlatButton(
            color: Colors.white10,
            child: Text('Write'),
            onPressed: () => _writeToDevice(characteristic),
          ),
        );
      }
      if (characteristic.properties.notify) {
        buttons.add(
          FlatButton(
            color: Colors.white10,
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
      List<ExpansionTile> servicesList = List<ExpansionTile>();
      for (BluetoothService service in _services) {
        /* Make list for characteristic in every service */
        List<Column> characteristicsList = List<Column>();
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          // String convertedValue = '';
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

    Column _dataView() {
      String valueReceived = _valueReceived.toString();

      if (valueReceived != 'null') {
        print('receive: $valueReceived');
        final decoded = utf8.decode(_valueReceived);
        _dataParser(decoded);
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "Body Temperature: " + _val1 + "°C",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            "Heart Rate: " + _val2 + " BPM",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    }

    // StreamBuilder<List<int>> _dataView() {
    //   return StreamBuilder<List<int>>(
    //     stream: _characteristic.value,
    //     initialData: [],
    //     builder: (ctx, snapshot) {
    //       String valueReceived =
    //           snapshot.data.toString();

    //       if (valueReceived != 'null') {
    //         print('receive: $valueReceived');
    //         final decoded = utf8.decode(snapshot.data);
    //         _dataParser(decoded);
    //       }
    //       return Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         crossAxisAlignment: CrossAxisAlignment.center,
    //         children: <Widget>[
    //           Text(
    //             "Body Temperature: " + _val1 + "°C",
    //             style: TextStyle(
    //               fontSize: 24,
    //               fontWeight: FontWeight.w700,
    //               letterSpacing: -0.5,
    //             ),
    //           ),
    //           Text(
    //             "Heart Rate: " + _val2 + " BPM",
    //             style: TextStyle(
    //               fontSize: 24,
    //               fontWeight: FontWeight.w700,
    //               letterSpacing: -0.5,
    //             ),
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // }

    CustomScrollView _scanningView(SliverList _bleDevicesList(),
        SliverToBoxAdapter _connectedDeviceWidget()) {
      return CustomScrollView(
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
              : SliverToBoxAdapter(child: _dataView()),
          // : _connectedDeviceWidget(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth App'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => AccountPage(),
                ),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isScanning ? Colors.orangeAccent : Colors.blue,
        child: Icon(
          _isScanning ? Icons.close : Icons.search,
          color: Colors.white,
        ),
        onPressed: () {
          _isScanning ? widget.flutterBlue.stopScan() : _startScanning();
        },
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: _scanningView(
          _bleDevicesList,
          _connectedDeviceWidget,
        ),
        // child: _dataView(),
      ),
    );
  }
}
