import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothExample(),
    );
  }
}

class BluetoothExample extends StatefulWidget {
  const BluetoothExample({super.key});

  @override
  _BluetoothExampleState createState() => _BluetoothExampleState();
}

class _BluetoothExampleState extends State<BluetoothExample> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();  // This instance is still necessary for certain actions
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;
  String receivedData = "No data received";

  @override
  void initState() {
    super.initState();

    // Start scanning for Bluetooth devices using the class itself (not the instance)
    FlutterBluePlus.startScan(timeout: Duration(seconds: 60));

    // Listen to the scan results
    FlutterBluePlus.scanResults.listen((scanResult) {
      for (ScanResult result in scanResult) {
        
        // Check if the device name matches ESP32 (you can customize this based on your ESP32 setup)
        if (result.device.name == "ESP32") {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    });

    // Stop scanning when the scan timeout ends
    FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning) {
        FlutterBluePlus.stopScan();
      }
    });
  }

  // Function to connect to the selected ESP32 device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
    });

    // Once connected, listen to the notifications (or read data) from the ESP32
    connectedDevice?.discoverServices().then((services) {
      // You can search for specific services and characteristics here to read data
      for (var service in services) {
        var characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            characteristic.setNotifyValue(true); // Enable notifications
            characteristic.value.listen((value) {
              // Handle received data here
              setState(() {
                receivedData = String.fromCharCodes(value);
              });
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // Disconnect from the device when the app is disposed
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32 Bluetooth Communication"),
      ),
      body: Column(
        children: <Widget>[
          // Display the list of available devices
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devicesList[index].name),
                  onTap: () {
                    // Connect to the tapped device
                    connectToDevice(devicesList[index]);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20),
          // Display received data from ESP32
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Received Data: $receivedData"),
          ),
        ],
      ),
    );
  }
}
