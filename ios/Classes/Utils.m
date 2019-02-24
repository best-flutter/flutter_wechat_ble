//
//  Utils.m
//  RNWechatBle
//
//  Created by JZoom on 2019/2/21.
//  Copyright © 2019 JZoom. All rights reserved.
//

#import "Utils.h"

@implementation Utils
+(NSString*)uuid:(CBUUID*)uuid{
    NSString* str = [uuid UUIDString];
    NSInteger len = [str length];
    if(len == 4){
        return [NSString stringWithFormat:@"0000%@-0000-1000-8000-00805F9B34FB",str];
    }
    return str;
    
}
@end
