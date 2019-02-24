//
//  BluetoothAdapter.h
//  JZoomBle
//
//  Created by 任雪亮 on 2017/11/25.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void (^StatusCallback)(NSInteger) ;
typedef void (^DiscoveryDeviceCallback)(NSDictionary*) ;
typedef void (^ConnectDeviceCallback)(CBPeripheral*,NSError*) ;
typedef void (^DiscoveryServiceCallback)(CBPeripheral*,NSError*) ;
typedef void (^DiscoveryCharacteristicsCallback)(CBPeripheral*,CBService*,NSError*) ;
typedef void (^NotifyChargeCallback)(CBPeripheral*,CBCharacteristic*,NSError*) ;
typedef void (^WriteValueCallback)(CBPeripheral*,CBCharacteristic*,NSError*) ;
typedef void (^UpdateValueCallback)(CBPeripheral*,CBCharacteristic*,NSError*) ;
typedef void (^ReadValueCallback)(CBPeripheral*,CBCharacteristic*,NSError*) ;

//连接状态发生变化
typedef void (^ConnectionStatusCallback)(CBPeripheral*,NSError*) ;

typedef enum _BluetoothAdapterResult{
    BluetoothAdapterResultOk,
    BluetoothAdapterResultNotInit,
    BluetoothAdapterResultDeviceNotFound,
    BluetoothAdapterResultDeviceNotConnected,
    BluetoothAdapterResultServiceNotFound,
    BluetoothAdapterResultCharacteristicsNotFound,
    BluetoothAdapterResultCharacteristicsPropertyNotSupport,   //不支持
    
}BluetoothAdapterResult;



@interface BluetoothAdapter : NSObject
//蓝牙状态
@property (nonatomic,readwrite,copy) StatusCallback statusCallback;
//发现设备
@property (nonatomic,readwrite,copy) DiscoveryDeviceCallback discoveryDeviceCallback;
//连接设备
@property (nonatomic,readwrite,copy) ConnectDeviceCallback connectDeviceCallback;
//发现服务
@property (nonatomic,readwrite,copy) DiscoveryServiceCallback discoveryServiceCallback;
//发现特征
@property (nonatomic,readwrite,copy) DiscoveryCharacteristicsCallback discoveryCharacteristicsCallback;
//特征的监听发生了变化
@property (nonatomic,readwrite,copy) NotifyChargeCallback notifyChageCallback;
//写入
@property (nonatomic,readwrite,copy) WriteValueCallback writeValueCallback;
//通知更新
@property (nonatomic,readwrite,copy) UpdateValueCallback updateValueCallback;

@property (nonatomic,readwrite,copy) ConnectionStatusCallback connectionStatusCallback;

@property (nonatomic,readwrite,copy) ReadValueCallback readValueCallback;


/**
 是否正在搜索设备
 */
@property (nonatomic,assign) BOOL discovering;

/**
 蓝牙是否可用
 */
@property (nonatomic,assign) BOOL available;


/**
 是否被初始化了
 */
-( BOOL)isInit;

/**
 打开蓝牙
 */
-(void)open:(StatusCallback)listener ;

/**
 关闭蓝牙
 */
-(void)close;


/**
 查找外设
 */
-(void)startDevieDiscovery:(NSArray*)services allowDuplicatesKey:(BOOL)allowDuplicatesKey interval:(NSInteger)interval ;

-(void)stopDevieDiscovery;

-(BluetoothAdapterResult)createConnection:(NSString*)deviceId;

-(BluetoothAdapterResult)closeConnection:(NSString*)deviceId;


/**
 获取已经连接的外设
 
 @return return value description
 */
-(NSArray<NSString*>*)getConnectedDevices;

//获取所有的设备
-(NSArray<CBPeripheral*>*)getDevices;

-(BluetoothAdapterResult)getServices:(NSString*)deviceId;

-(BluetoothAdapterResult)getCharacteristics:(NSString*)deviceId serviceId:(NSString*)serviceId;

//设置通知状态，必须是可以通知的，才能设置
-(BluetoothAdapterResult)setNotify:(NSString*)deviceId serviceId:(NSString*)serviceId characteristicId:(NSString*)characteristicId state:(BOOL)state;

-(BluetoothAdapterResult)writeValue:(NSString*)deviceId serviceId:(NSString*)serviceId characteristicId:(NSString*)characteristicId value:(NSData*)value;

-(BluetoothAdapterResult)readValue:(NSString*)deviceId serviceId:(NSString*)serviceId characteristicId:(NSString*)characteristicId;
/*
 -(BOOL)write;
 
 -(BOOL)read;
 */


@end
