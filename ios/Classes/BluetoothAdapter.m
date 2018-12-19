//
//  BluetoothAdapter.m
//  JZoomBle
//
//  Created by 任雪亮 on 2017/11/25.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "BluetoothAdapter.h"



@interface BluetoothAdapter()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
  CBCentralManager *_manager;
  NSInteger _state;
  NSInteger _interval;
  //上一次广播发现设备的时间
  NSUInteger _lastBrodcastDiscoveryDevice;
  //设备列表
  NSMutableDictionary<NSString*,CBPeripheral*>* _devices;
  //连接上的设备
  NSMutableSet<NSString*>* _connectedDevices;
}


@property (nonatomic,readwrite,copy) StatusCallback statusCallbackOnce;
@end

@implementation BluetoothAdapter

-( BOOL)isInit{
  return _manager != nil;
}

-(void)open:(StatusCallback)listener{
  
  _discovering = NO;
  _available = NO;
  
  _manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
  _statusCallbackOnce = listener;
 
}

-(void)dealloc{
  [self close];
}

-(void)close{
  _devices= nil;
  _manager = nil;
  _connectedDevices = nil;
  
}


-(void)startDevieDiscovery:(NSArray*)services allowDuplicatesKey:(BOOL)allowDuplicatesKey interval:(NSInteger)interval {
  _discovering = YES;
  
  
  _interval = interval;
  _devices = [[NSMutableDictionary alloc]init];
 _connectedDevices = [[NSMutableSet alloc]init];
  
  NSMutableArray<CBUUID*>* uuidServices = nil;
  if(services && services.count > 0){
    uuidServices = [[NSMutableArray alloc]initWithCapacity:services.count];
    
    for(int i=0; i < services.count; ++i){
      [uuidServices addObject:[CBUUID UUIDWithString:services[i]]];
    }
    
  }
  
  [_manager scanForPeripheralsWithServices:uuidServices options:@{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:allowDuplicatesKey] }];
}

-(void)stopDevieDiscovery{
  [_manager stopScan];
}

-(BluetoothAdapterResult)createConnection:(NSString *)deviceId{
  
  if(![self isInit]){
     return BluetoothAdapterResultNotInit;
  }
  
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultDeviceNotFound;
  }
  
  
  [_manager connectPeripheral:device options:nil];
  
  return BluetoothAdapterResultOk;
}

-(BluetoothAdapterResult)closeConnection:(NSString*)deviceId{
  if(![self isInit]){
    return BluetoothAdapterResultNotInit;
  }
  
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultOk;
  }
  [_manager cancelPeripheralConnection:device];
  
  return BluetoothAdapterResultOk;
  
  
}

-(NSArray<NSString*>*)getConnectedDevices{
  return [_connectedDevices allObjects];
}
-(NSArray<CBPeripheral*>*)getDevices{
  return [_devices allValues];
}
-(BluetoothAdapterResult)getServices:(NSString*)deviceId{
  
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultDeviceNotFound;
  }
  //要连接才行
  if(![_connectedDevices containsObject:deviceId]){
    return BluetoothAdapterResultDeviceNotConnected;
  }
  
  if(device.services){
    if(_discoveryServiceCallback!=nil){
      _discoveryServiceCallback( device ,nil);
    }
    
    return BluetoothAdapterResultOk;
  }
  //查找服务
  device.delegate = self;
  [device discoverServices:nil];
 
  return BluetoothAdapterResultOk;
  
}

-(BluetoothAdapterResult)getCharacteristics:(NSString*)deviceId serviceId:(NSString*)serviceId{
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultDeviceNotFound;
  }
  //要连接才行
  if(![_connectedDevices containsObject:deviceId]){
    return BluetoothAdapterResultDeviceNotConnected;
  }
  
  if(device.services){
    //如果找不到，那么就serviceNotFound
    
    for(CBService* service in device.services){
      
      if([service.UUID.UUIDString isEqualToString:serviceId]){
        if(service.characteristics){
          //返回这个
          
          if(_discoveryCharacteristicsCallback){
            _discoveryCharacteristicsCallback( device, service ,  nil);
          }
          
          return BluetoothAdapterResultOk;
        }
        [device discoverCharacteristics:nil forService:service];
        return BluetoothAdapterResultOk;
      }
    }
  }
  
  return BluetoothAdapterResultServiceNotFound;
}

-(CBService*)findService:(NSArray*)services serviceId:(NSString*)serviceId{
  for(CBService* service in services){
    if([service.UUID.UUIDString isEqualToString:serviceId]){
      return service;
    }
  }
  return nil;
}

-(CBCharacteristic*)findCharacteristic:(NSArray*)characteristics characteristicId:(NSString*)characteristicId{
  for(CBCharacteristic* characteristic in characteristics){
    if([characteristic.UUID.UUIDString isEqualToString:characteristicId]){
      return characteristic;
    }
  }
  return nil;
}
-(BluetoothAdapterResult)writeValue:(NSString*)deviceId serviceId:(NSString*)serviceId characteristicId:(NSString*)characteristicId value:(NSData*)value{
  if(![self isInit]){
    return BluetoothAdapterResultNotInit;
  }
  
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultDeviceNotFound;
  }
  
  if(![_connectedDevices containsObject:deviceId]){
    return BluetoothAdapterResultDeviceNotConnected;
  }
  
  CBService* services = [self findService:device.services serviceId:serviceId];
  if(!services){
    return BluetoothAdapterResultServiceNotFound;
  }
  CBCharacteristic* characteristic = [self findCharacteristic:services.characteristics characteristicId:characteristicId];
  if(!characteristic){
    return BluetoothAdapterResultCharacteristicsNotFound;
  }
  /*
  if( (characteristic.properties & CBCharacteristicPropertyWrite) <= 0){
    return BluetoothAdapterResultCharacteristicsPropertyNotSupport;
  }*/

  if(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse){
     [device writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
  }else{
     [device writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
  }
  
 
  
  return BluetoothAdapterResultOk;
}

-(BluetoothAdapterResult)readValue:(NSString*)deviceId serviceId:(NSString*)serviceId characteristicId:(NSString*)characteristicId{
  if(![self isInit]){
    return BluetoothAdapterResultNotInit;
  }
  
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultDeviceNotFound;
  }
  
  if(![_connectedDevices containsObject:deviceId]){
    return BluetoothAdapterResultDeviceNotConnected;
  }
  
  CBService* services = [self findService:device.services serviceId:serviceId];
  if(!services){
    return BluetoothAdapterResultServiceNotFound;
  }
  CBCharacteristic* characteristic = [self findCharacteristic:services.characteristics characteristicId:characteristicId];
  if(!characteristic){
    return BluetoothAdapterResultCharacteristicsNotFound;
  }
  
  if( (characteristic.properties & CBCharacteristicPropertyRead) <= 0){
    return BluetoothAdapterResultCharacteristicsPropertyNotSupport;
  }
  
  
  [device readValueForCharacteristic:characteristic];
  
  if(_readValueCallback!=nil){
    _readValueCallback(device,characteristic,nil);
  }
  
  return 0;
  
  
}

-(BluetoothAdapterResult)setNotify:(NSString*)deviceId serviceId:(NSString*)serviceId characteristicId:(NSString*)characteristicId state:(BOOL)state{
  
  if(![self isInit]){
    return BluetoothAdapterResultNotInit;
  }
  
  CBPeripheral* device = [_devices objectForKey:deviceId];
  if(!deviceId){
    return BluetoothAdapterResultDeviceNotFound;
  }
  
  if(![_connectedDevices containsObject:deviceId]){
    return BluetoothAdapterResultDeviceNotConnected;
  }
  
  CBService* services = [self findService:device.services serviceId:serviceId];
  if(!services){
    return BluetoothAdapterResultServiceNotFound;
  }
  CBCharacteristic* characteristic = [self findCharacteristic:services.characteristics characteristicId:characteristicId];
  if(!characteristic){
    return BluetoothAdapterResultCharacteristicsNotFound;
  }
  
  if( (characteristic.properties & CBCharacteristicPropertyNotify) <= 0){
    return BluetoothAdapterResultCharacteristicsPropertyNotSupport;
  }
  
  if(characteristic.isNotifying!=state){
    [device setNotifyValue:state forCharacteristic:characteristic];
  }else{
    //报告成功
    if(_notifyChageCallback!=nil){
      _notifyChageCallback(device,characteristic,nil);
    }
  }
  
  
  
  return BluetoothAdapterResultOk;
}


#pragma CBPeripheralDelegate
//发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
  //报告发现服务
  if(_discoveryServiceCallback!=nil){
    _discoveryServiceCallback( peripheral,error );
  }
}
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
  //报告发现特征
  if(_discoveryCharacteristicsCallback){
    _discoveryCharacteristicsCallback( peripheral, service ,  error);
  }
}


-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
  
  if(_writeValueCallback!=nil){
    _writeValueCallback(peripheral,characteristic,error);
  }
}


-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
  
  if(_updateValueCallback!=nil){
    _updateValueCallback(peripheral,characteristic,error);
  }
  
  
  NSLog(@"%@",characteristic.value);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
  
  if(_notifyChageCallback!=nil){
    _notifyChageCallback(peripheral,characteristic,error);
  }
  
  
  
}

#pragma CBCentralManagerDelegate


- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
  _state = central.state;
  if(_state == CBCentralManagerStatePoweredOn){
    _available = YES;
  }else{
    _available = NO;
  }
  
  if(_statusCallbackOnce!=nil){
    _statusCallbackOnce(_state);
    _statusCallbackOnce = nil;
  }
 
  
  if(_statusCallback!=nil){
    _statusCallback(_state);
  }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
  
  NSString* uuidOfDev = peripheral.identifier.UUIDString;
  //找到外设
 // NSLog(@"找到外设%@",peripheral.identifier.UUIDString);
  
  CBPeripheral* deviceInfo = [_devices objectForKey:uuidOfDev];
  if(!deviceInfo){
    //这两个有效，其他只在广播的时候发送广播
    deviceInfo = peripheral;
    _devices[uuidOfDev] = deviceInfo;
  }
  
  [self reportDiscoveryDeviced:peripheral advertisementData:advertisementData RSSI:RSSI];
  
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
  
  //这里成功了
  [_connectedDevices addObject:peripheral.identifier.UUIDString];
  //并且报成功
  if(_connectDeviceCallback!=nil){
    _connectDeviceCallback(peripheral,nil);
  }
  
  
  if(_connectionStatusCallback!=nil){
    _connectionStatusCallback(peripheral,nil);
  }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
  
  if(_connectDeviceCallback!=nil){
    _connectDeviceCallback(peripheral,error);
  }
  
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
  //断开
  if(_connectionStatusCallback!=nil){
    _connectionStatusCallback(peripheral,nil);
  }
  
  [_connectedDevices removeObject:peripheral.identifier.UUIDString];
  
}


#pragma private


-(void)reportDiscoveryDeviced:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
  
  _lastBrodcastDiscoveryDevice = [NSDate timeIntervalSinceReferenceDate];
  
  if(_discoveryDeviceCallback!=nil){
    _discoveryDeviceCallback(
                             @{
                               @"name" : peripheral.name ? peripheral.name : @"",
                               @"deviceId" :peripheral.identifier.UUIDString,
                               @"RSSI" : RSSI,
                               }
                             
                             );
    
  }
  
  
}

@end
