#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;
uint32_t value = 0;

// 定义服务UUID和特征UUID
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// 连接回调
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

void setup() {
  Serial.begin(115200);

  // 初始化蓝牙
  BLEDevice::init("ESP32");

  // 创建服务器
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // 创建服务和特征
  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // 设置描述
  pCharacteristic->addDescriptor(new BLE2902());
  
  // 启动服务
  pService->start();

  // 开始广播
  pServer->getAdvertising()->start();
  Serial.println("Waiting for a client connection...");
}

void loop() {
  Serial.print("Stand by....\n");
  delay(1000);
  if (deviceConnected) {
    // 生成随机数
    value = random(0, 100); // 随机数范围可以调整
    pCharacteristic->setValue(value);
    pCharacteristic->notify(); // 通知客户端
    Serial.print("Sent random value: ");
    Serial.println(value);
    delay(500); // 500ms 间隔
    
  }
}
