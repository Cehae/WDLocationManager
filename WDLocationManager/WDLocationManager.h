//
//  WDLocationManager.h
//  LocationTest
//
//  Created by huylens on 16/12/20.
//  Copyright © 2016年 WDD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


typedef void(^ResultBlock)(CLLocation *currentLocation,CLLocationCoordinate2D currentCoordinate2D, CLPlacemark *placemark, NSString * currentLocationStr,NSString * error);

@interface WDLocationManager : NSObject


+ (WDLocationManager *)sharedInstance;

/**
 *  获取当前位置
 *
 *  @param block 获取当前位置后处理的block
 */
- (void)getCurrentLocation:(ResultBlock)block;
@end
