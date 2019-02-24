//
//  Utils.h
//  RNWechatBle
//
//  Created by JZoom on 2019/2/21.
//  Copyright © 2019 JZoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+(NSString*)uuid:(CBUUID*)uuid;

@end

NS_ASSUME_NONNULL_END
