#import "FlutterWechatBlePlugin.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothAdapter.h"

/*
 0  ok  正常
 10000  not init  未初始化蓝牙适配器
 10001  not available  当前蓝牙适配器不可用
 10002  no device  没有找到指定设备
 10003  connection fail  连接失败
 10004  no service  没有找到指定服务
 10005  no characteristic  没有找到指定特征值
 10006  no connection  当前连接已断开
 10007  property not support  当前特征值不支持此操作
 10008  system error  其余所有系统上报的异常
 10009  system not support  Android 系统特有，系统版本低于 4.3 不支持BLE
 */
#define NOT_INIT @"10000"
#define NOT_AVALIABLE @"10001"
#define NO_DEVICE @"10002"
#define CONNECTION_FAIL @"10003"
#define NO_SERVICE @"10004"
#define NO_CHARACTERISTIC @"10005"
#define NO_CONNECTION @"10006"
#define PROPERTY_NOT_SUPPOTT @"10007"
#define SYSTEM_ERROR @"10008"
#define SYSTEM_NOT_SUPPORT @"10009"


///We have to define the data structure，whitch represent ok or error
//
// code: null is ok, other is error
// other data


@interface FlutterWechatBlePlugin()

@property (nonatomic,retain) BluetoothAdapter* adapter;
@property (nonatomic,retain) FlutterMethodChannel* channel;

@end



@implementation FlutterWechatBlePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_wechat_ble"
            binaryMessenger:[registrar messenger]];
  FlutterWechatBlePlugin* instance = [[FlutterWechatBlePlugin alloc] init];
    instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
}


-(id)init{
    if(self=  [super init]){
        _adapter = [[BluetoothAdapter alloc]init];
        __weak FlutterWechatBlePlugin* __self = self;
        _adapter.discoveryDeviceCallback = ^(NSDictionary * device) {
            [__self.channel invokeMethod:@"foundDevice" arguments:device];
        };
        
        _adapter.connectionStatusCallback = ^(CBPeripheral * c, NSError * e) {
            //c.state;
            if(e){
                //did failed
                NSLog(@"CBPeripheral %@ did not connect right ",c);
            }else{
                
                
                
            }
            
        } ;
       // _adapter.connectDeviceCallback(<#CBPeripheral *#>, <#NSError *#>)
        
        _adapter.updateValueCallback = ^(CBPeripheral * device, CBCharacteristic * character, NSError * error) {
            if(!error){
                [__self.channel
                 invokeMethod:@"valueUpdate"
               arguments:@{
                            @"characteristicId":character.UUID.UUIDString,
                            @"serviceId" : character.service.UUID.UUIDString,
                            @"deviceId" : device.identifier.UUIDString,
                            @"value" : [ FlutterWechatBlePlugin toString:character.value ]
                            }];
            }
            
        };
    }
    return self;
}



- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* method = call.method;
  if ([@"getPlatformVersion" isEqualToString:method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"openBluetoothAdapter" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"closeBluetoothAdapter" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"startBluetoothDevicesDiscovery" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"stopBluetoothDevicesDiscovery" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"createBLEConnection" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"closeBLEConnection" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"getBluetoothDevices" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  }else if([@"getConnectedBluetoothDevices" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  } else if([@"getBLEDeviceServices" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  } else if([@"getBLEDeviceCharacteristics" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  } else if([@"readBLECharacteristicValue" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  } else if([@"writeBLECharacteristicValue" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  } else if([@"notifyBLECharacteristicValueChange" isEqualToString:method]){
      [self openBluetoothAdapter:call.arguments callback:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

/**
 0  ok  正常
 10000  not init  未初始化蓝牙适配器
 
 10001  not available  当前蓝牙适配器不可用
 
 
 
 10002  no device  没有找到指定设备
 10003  connection fail  连接失败
 10004  no service  没有找到指定服务
 10005  no characteristic  没有找到指定特征值
 10006  no connection  当前连接已断开
 10007  property not support  当前特征值不支持此操作
 10008  system error  其余所有系统上报的异常
 10009  system not support  Android 系统特有，系统版本低于 4.3 不支持BLE
 */
-(void)openBluetoothAdapter:(NSDictionary*)dic callback:(FlutterResult)callback{
    [_adapter open:^(NSInteger status) {
        if(status == CBCentralManagerStatePoweredOn){
            callback(@{});
        }else{
            callback(@{@"code":NOT_AVALIABLE});
        }
    }];
    
}

-(void) closeBluetoothAdapter: (NSDictionary*)dic callback:(FlutterResult)callback {
    [_adapter close];
    callback(@{});
}

#define CHECK(x) [FlutterWechatBlePlugin retToCallback:x callback:callback ]
#define CHECK_INIT if(!_adapter.isInit){ \
callback(@{@"code":NOT_INIT}); \
return; \
} \

-(void)startBluetoothDevicesDiscovery: (NSDictionary*)dic callback:(FlutterResult)callback {

    CHECK_INIT;

    [_adapter startDevieDiscovery:[dic objectForKey:@"services"] allowDuplicatesKey: [[dic objectForKey:@"allowDuplicatesKey"]boolValue]   interval:[[dic objectForKey:@"interval"]integerValue]];
    callback(@{});
}
//10000 未初始化
-(void)stopBluetoothDevicesDiscovery: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    [_adapter stopDevieDiscovery];
    callback(@{});
}



-(void)createBLEConnection: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    __weak BluetoothAdapter* __adapter = _adapter;
    
    _adapter.connectDeviceCallback = ^(CBPeripheral * device,NSError* error) {
        if(error){
            callback(@{@"code":CONNECTION_FAIL});
        }else{
            callback(@{});
        }
        __adapter.connectDeviceCallback  = nil;
    };
    
    NSString* deviceId = dic[@"deviceId"];
    
    CHECK([_adapter createConnection:deviceId]);
    
    
}
-(void)closeBLEConnection: (NSDictionary*)dic callback:(FlutterResult)callback{
    
   
    CHECK_INIT;
    
    
    NSString* deviceId = [dic objectForKey:@"deviceId"];
    if(!deviceId){
        callback(@{@"code":NO_DEVICE});
        return;
    }
    
    if(![_adapter closeConnection:deviceId]){
      
    }
    callback(@{});
    
}


/**
 获取在小程序蓝牙模块生效期间所有已发现的蓝牙设备，包括已经和本机处于连接状态的设备。
 
 
 success返回参数：
 
 参数  类型  说明
 devices  Array  uuid 对应的的已连接设备列表
 errMsg  String  成功：ok，错误：详细信息
 
 
 
 
 device 对象
 蓝牙设备信息
 
 
 name  String  蓝牙设备名称，某些设备可能没有
 deviceId  String  用于区分设备的 id
 RSSI  Number  当前蓝牙设备的信号强度
 advertisData  ArrayBuffer  当前蓝牙设备的广播数据段中的ManufacturerData数据段 （注意：vConsole 无法打印出 ArrayBuffer 类型数据）
 advertisServiceUUIDs  Array  当前蓝牙设备的广播数据段中的ServiceUUIDs数据段
 localName  String  当前蓝牙设备的广播数据段中的LocalName数据段
 
 */
-(void)getBluetoothDevices: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSArray* devices  = [_adapter getDevices];
    
    //resolve(@[[self deviceToArray:devices]]);
    callback(@[@{@"devices":[self deviceToArray:devices]}]);
    
}


-(NSArray*)deviceToArray:(NSArray*)devices{
    
    NSMutableArray* result = [[NSMutableArray alloc]init];
    for(CBPeripheral* device in devices){
        
        [result addObject:@{@"name":device.name,@"deviceId":device.identifier.UUIDString}];
        
    }
    return result;
}

/**
 根据 uuid 获取处于已连接状态的设备
 
 */
-(void)getConnectedBluetoothDevices: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSArray* devices = [_adapter getConnectedDevices];
    
    callback(@[@{@"devices":[self deviceToArray:devices]}]);
    
}




-(void)getBLEDeviceServices: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSString* deviceId = [dic objectForKey:@"deviceId"];
    if(!deviceId){
        callback(@{@"code":NO_DEVICE});
        return;
    }
    
    
    __weak BluetoothAdapter* __adapter = _adapter;
    
    _adapter.discoveryServiceCallback = ^(CBPeripheral * device, NSError * error) {
        if(error){
            callback(@{@"code":SYSTEM_ERROR});
        }else{
            //发现了服务
            NSMutableArray* result = [[NSMutableArray alloc]initWithCapacity:device.services.count];
            for(CBService* service in device.services){
                [result addObject:@{
                                    @"uuid": service.UUID.UUIDString,
                                    @"isPrimary":[NSNumber numberWithBool: service.isPrimary]
                                    }];
            }
            callback(@{@"services":result});
        }
        __adapter.discoveryServiceCallback = nil;
    };
    
    CHECK([_adapter getServices:deviceId]);
    
}

+(void)retToCallback:(BluetoothAdapterResult)ret callback:(FlutterResult)callback{
    
    if(ret == BluetoothAdapterResultOk){
        return ;
    }
    if(ret==BluetoothAdapterResultNotInit){
        callback(@{@"code":NOT_INIT});
        return;
    }
    if(ret==BluetoothAdapterResultDeviceNotFound){
        callback(@{@"code":NO_DEVICE});
        return;
    }
    
    if(ret==BluetoothAdapterResultServiceNotFound){
        callback(@{@"code":NO_SERVICE});
        return;
    }
    
    if(ret==BluetoothAdapterResultCharacteristicsNotFound){
        callback(@{@"code":NO_CHARACTERISTIC});
        return;
    }
    
    if(ret==BluetoothAdapterResultDeviceNotConnected){
        callback(@{@"code":NO_CONNECTION});
        return;
    }
    if(ret==BluetoothAdapterResultCharacteristicsPropertyNotSupport){
        callback(@{@"code":PROPERTY_NOT_SUPPOTT});
        return;
    }
    
    
    
}


-(void)getBLEDeviceCharacteristics: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSString* deiviceId = [dic objectForKey:@"deviceId"];
    NSString* serviceId = [dic objectForKey:@"serviceId"];
    
    _adapter.discoveryCharacteristicsCallback = ^(CBPeripheral * device, CBService * service, NSError *error) {
        if(error){
            callback(@{@"code":SYSTEM_ERROR});
        }else{
            //发现了服务
            NSMutableArray* result = [[NSMutableArray alloc]initWithCapacity:service.characteristics.count];
            for(CBCharacteristic* characteristic in service.characteristics){
                [result addObject:@{
                                    @"uuid":characteristic.UUID.UUIDString,
                                    @"properties":@{
                                            @"read" :[NSNumber numberWithBool:( characteristic.properties & CBCharacteristicPropertyRead)],
                                            @"write" :[NSNumber numberWithBool: (characteristic.properties & CBCharacteristicPropertyWrite) || (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)   ],
                                            @"notify":[NSNumber numberWithBool:( characteristic.properties & CBCharacteristicPropertyNotify)],
                                            @"indicate":[NSNumber numberWithBool:( characteristic.properties & CBCharacteristicPropertyIndicate)],
                                            
                                            }
                                    }];
            }
            
            callback(@{@"characteristics": result  });
        }
        
    };
    
    CHECK([_adapter getCharacteristics:deiviceId serviceId:serviceId]);
}


-(void)readBLECharacteristicValue: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSString* deviceId = dic[@"deviceId"];
    NSString* serviceId = dic[@"serviceId"];
    NSString* characteristicId = dic[@"characteristicId"];
    // NSString* value = dic[@"value"];    //二进制
    
    // value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    __weak BluetoothAdapter* __adapter = _adapter;
    _adapter.readValueCallback = ^(CBPeripheral * device, CBCharacteristic * c, NSError * error) {
        if(error){
            callback(@{@"code":SYSTEM_ERROR});
        }else{
            callback(@{});
        }
        
        __adapter.readValueCallback = nil;
        
    };
    
    CHECK([_adapter readValue:deviceId serviceId:serviceId characteristicId:characteristicId]);
    
}

/**
 deviceId  String  是  蓝牙设备 id，参考 device 对象
 serviceId  String  是  蓝牙特征值对应服务的 uuid
 characteristicId  String  是  蓝牙特征值的 uuid
 value  ArrayBuffer  是  蓝牙设备特征值对应的二进制值
 */
-(void)writeBLECharacteristicValue: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSString* deviceId = dic[@"deviceId"];
    NSString* serviceId = dic[@"serviceId"];
    NSString* characteristicId = dic[@"characteristicId"];
    NSString* value = dic[@"value"];    //二进制
    
    value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    __weak BluetoothAdapter* __adapter = _adapter;
    _adapter.writeValueCallback = ^(CBPeripheral * device, CBCharacteristic * c, NSError * error) {
        if(error){
            callback(@{@"code":SYSTEM_ERROR});
        }else{
            callback(@{});
        }
        
        __adapter.writeValueCallback = nil;
        
    };
    
    CHECK([_adapter writeValue:deviceId serviceId:serviceId characteristicId:characteristicId value: [ FlutterWechatBlePlugin toHex:value] ]);
}

/**
 deviceId  String  是  蓝牙设备 id，参考 device 对象
 serviceId  String  是  蓝牙特征值对应服务的 uuid
 characteristicId  String  是  蓝牙特征值的 uuid
 state  Boolean  是  true: 启用 notify; false: 停用 notify
 */
-(void)notifyBLECharacteristicValueChange: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
    NSString* deviceId = dic[@"deviceId"];
    NSString* serviceId = dic[@"serviceId"];
    NSString* characteristicId = dic[@"characteristicId"];
    BOOL state = [dic[@"state"]boolValue];
    
    __weak BluetoothAdapter* __adapter = _adapter;
    
    _adapter.notifyChageCallback = ^(CBPeripheral * device, CBCharacteristic * characteristic, NSError * error) {
        if(error){
            callback(@{@"code":SYSTEM_ERROR});
        }else{
            callback(@{});
        }
        __adapter.notifyChageCallback = nil;
    };
    CHECK([_adapter setNotify:deviceId serviceId:serviceId characteristicId:characteristicId state:state]);
}

-(void)onBLEConnectionStateChange: (NSDictionary*)dic callback:(FlutterResult)callback {
   
    CHECK_INIT;
   
    
}



-(void)onBLECharacteristicValueChange: (NSDictionary*)dic callback:(FlutterResult)callback {
    
    CHECK_INIT;
    
}
+(NSData*)toHex:(NSString*)hexString{
    
    NSMutableData* data = [[NSMutableData alloc]initWithCapacity:hexString.length/2];
    [FlutterWechatBlePlugin toHex:hexString hex:data];
    return data;
}

+(int)toDigit:(int)codePoint{
    // Optimized for ASCII
    int result = -1;
    if ('0' <= codePoint && codePoint <= '9') {
        result = codePoint - '0';
    } else if ('a' <= codePoint && codePoint <= 'z') {
        result = 10 + (codePoint - 'a');
    } else if ('A' <= codePoint && codePoint <= 'Z') {
        result = 10 + (codePoint - 'A');
    }
    return result;
}
+(NSString*)toString:(NSData*)data{
    NSUInteger len = [data length];
    return [FlutterWechatBlePlugin toString:data len:len];
}
+(NSString*)toString:(NSData*)data len:(NSInteger)len{
    char *chars = (char *)[data bytes];
    NSMutableString *hexString = [[NSMutableString alloc]init];
    for (NSUInteger i=0; i<len; i++) {
        [hexString appendString:[NSString stringWithFormat:@"%0.2hhx",chars[i]]];
    }
    return hexString;
}
+(void)toHex:(NSString*)data hex:(NSMutableData*)dest{
    
    int len = (int)data.length;
    if( (len & 0x0 )!= 0){
        @throw [[NSError alloc]initWithDomain:@"不是偶数" code:0 userInfo:nil];
    }
    for( int i=0 , j = 0; j < len; ++i){
        
        int f = [FlutterWechatBlePlugin toDigit:[data characterAtIndex:j]] << 4;
        ++j;
        f |=[FlutterWechatBlePlugin toDigit:[data characterAtIndex:j]];
        ++j;
        
        Byte b = (Byte)(f & 0xff);
        
        [dest appendBytes:&b length:1];
        
    }
    
    
}
@end
