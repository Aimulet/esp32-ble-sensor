import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fblue show BluetoothService;
import 'package:fl_chart/fl_chart.dart';
import 'login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aimulet Smart Sensor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: const BluetoothScanPage(),
    );
  }
}

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({Key? key}) : super(key: key);

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final BluetoothService _bluetoothService = BluetoothService.instance;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  // 添加连接状态和数据接收变量
  BluetoothDevice? connectedDevice;
  String receivedData = '';

  // 添加数据点列表用于绘制图表
  final List<FlSpot> dataPoints = [];
  final int maxDataPoints = 50; // 最多显示的数据点数量
  double xValue = 0;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    print('初始化蓝牙监听...');
    
    // 监听蓝牙状态变化
    FlutterBluePlus.adapterState.listen((state) {
      print('蓝牙状态变化: $state');
    });

    // 监听扫描结果
    FlutterBluePlus.scanResults.listen((results) {
      print('收到扫描结果，数量: ${results.length}');
      if (mounted) {
        setState(() {
          scanResults = results;
          for (var result in results) {
            print('---设备信息---');
            print('设备名称: ${result.device.platformName}');
            print('设备ID: ${result.device.remoteId}');
            print('信号强度: ${result.rssi}');
            print('广播数据: ${result.advertisementData.serviceUuids}');
            print('制造商数据: ${result.advertisementData.manufacturerData}');
            print('本地名称: ${result.advertisementData.localName}');
            print('发送功率: ${result.advertisementData.txPowerLevel}');
            print('-------------');
          }
        });
      }
    }, onError: (error) {
      print('扫描结果监听错误: $error');
    });

    // 监听扫描状态
    FlutterBluePlus.isScanning.listen((scanning) {
      print('扫描状态变化: $scanning');
      if (mounted) {
        setState(() => isScanning = scanning);
      }
    });
  }

  Future<void> _startScan() async {
    print('准备开始扫描...');
    
    if (!await _bluetoothService.checkPermissions()) {
      print('权限检查失败');
      _showError('缺少必要权限');
      return;
    }

    if (!await _bluetoothService.checkBluetoothStatus()) {
      print('蓝牙状态检查失败');
      _showError('请开启蓝牙');
      return;
    }

    print('清空之前的扫描果');
    setState(() => scanResults.clear());
    
    print('调用扫描服务');
    await _bluetoothService.startScan();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: isScanning ? _bluetoothService.stopScan : _startScan,
            child: Text(isScanning ? '停止扫描' : '开始扫描'),
          ),
        ),
        
        // 当已连接设备时，只显示已连接设备的信息和图表
        if (connectedDevice != null) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                title: Text('已连接: ${connectedDevice!.platformName}'),
                subtitle: Text('接收数据: $receivedData'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _disconnectDevice,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]
        // 未连接设备时，显示扫描列表
        else
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return ListTile(
                  title: Text(result.device.platformName.isEmpty 
                      ? "未命名设备" 
                      : result.device.platformName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAC: ${result.device.remoteId}'),
                      Text('信号强度: ${result.rssi} dBm'),
                    ],
                  ),
                  trailing: Text('${result.rssi} dBm'),
                  onTap: () => _showConnectionDialog(result.device),
                );
              },
            ),
          ),
      ],
    );
  }

  // 添加连接对话框
  Future<void> _showConnectionDialog(BluetoothDevice device) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('连接到设备'),
        content: Text('是否连接到 ${device.platformName}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToDevice(device);
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  // 添加连接设备方法
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        dataPoints.clear(); // 清空之前的数据
        xValue = 0;
      });
      _showError('连接成功');
      
      List<fblue.BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              if (value.isNotEmpty) {
                setState(() {
                  // 更新数值显示
                  receivedData = value[0].toString();
                  
                  // 添加新的数据点
                  dataPoints.add(FlSpot(xValue, value[0].toDouble()));
                  xValue += 1;
                  
                  // 保持最大数据点数量
                  if (dataPoints.length > maxDataPoints) {
                    dataPoints.removeAt(0);
                    // 调整所有点的x坐标
                    for (int i = 0; i < dataPoints.length; i++) {
                      dataPoints[i] = FlSpot(i.toDouble(), dataPoints[i].y);
                    }
                    xValue = dataPoints.length.toDouble();
                  }
                });
                print('到数据: $receivedData (原始数据: $value)');
              }
            });
          }
        }
      }
    } catch (e) {
      print('连接错误: $e');
      _showError('连接失败');
    }
  }

  // 添加断开连接方法
  Future<void> _disconnectDevice() async {
    try {
      await connectedDevice?.disconnect();
      setState(() {
        connectedDevice = null;
        receivedData = '';
        dataPoints.clear();
        xValue = 0;
      });
      _showError('已断开连接');
    } catch (e) {
      print('断开连接错误: $e');
    }
  }

  @override
  void dispose() {
    _disconnectDevice();
    _bluetoothService.stopScan();
    super.dispose();
  }
}

class BluetoothService {
  static final BluetoothService instance = BluetoothService._();
  BluetoothService._();

  Future<bool> checkPermissions() async {
    try {
      await FlutterBluePlus.turnOn();
      return true;
    } catch (e) {
      print('权限检查错误: $e');
      return false;
    }
  }

  Future<bool> checkBluetoothStatus() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        return false;
      }
      
      var adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('蓝牙状态检查错误: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print('开始扫描错误: $e');
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
