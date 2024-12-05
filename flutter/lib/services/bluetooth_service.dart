import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static final BluetoothService instance = BluetoothService._internal();
  
  BluetoothService._internal();

  Future<bool> checkPermissions() async {
    // 检查蓝牙权限
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<bool> checkBluetoothStatus() async {
    try {
      // 检查蓝牙是否开启
      if (await FlutterBluePlus.isSupported == false) {
        return false;
      }
      
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('检查蓝牙状态错误: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    try {
      // 开始扫描
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print('开始扫描错误: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('停止扫描错误: $e');
    }
  }
} 